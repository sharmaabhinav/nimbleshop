class Order < ActiveRecord::Base

  # to allow extensions to store any type of information
  store :metadata

  attr_accessor   :validate_email, :billing_address_same_as_shipping
  attr_protected  :number

  belongs_to  :user
  belongs_to  :payment_method
  belongs_to  :shipping_method

  has_one     :shipping_address,  dependent:  :destroy
  has_one     :billing_address,   dependent:  :destroy

  has_many    :shipments
  has_many    :line_items,   dependent:  :destroy
  has_many    :products,     through:    :line_items
  has_many    :payment_transactions, dependent:  :destroy

  accepts_nested_attributes_for :shipping_address, allow_destroy: true
  accepts_nested_attributes_for :billing_address,  reject_if: :billing_address_same_as_shipping?  , allow_destroy: true

  delegate :tax,            to: :tax_calculator
  delegate :shipping_cost,  to: :shipping_cost_calculator

  validates :email, email: true, if: :validate_email

  # cancelled is when third party service like Splitable sends a webhook stating that order has been cancelled
  validates_inclusion_of :shipping_status, in: %W( nothing_to_ship shipped partially_shipped shipping_pending cancelled )
  validates_inclusion_of :status,          in: %W( open closed )
  validates_inclusion_of :checkout_status, in: %W( items_added_to_cart billing_address_provided shipping_method_provided )


  before_create :set_order_number

  # goes into pending state when sold using cash on delivery but not yet paid
  # capture is a method defined on kernel
  state_machine :payment_status, initial: :abandoned do
    event(:authorize) { transition abandoned:   :authorized }
    event(:pending)   { transition abandoned:   :pending    }
    event(:kapture )  { transition authorized:  :paid       }
    event(:refund)    { transition paid:        :refunded   }

    event(:purchase)  { transition [:abandoned,  :pending] =>  :paid       }
    event(:void)      { transition [:authorized, :pending] =>  :cancelled  }

    state all - [ :abandoned ] do
      validates :payment_method, presence: true
    end
  end

  state_machine :shipping_status, initial: :nothing_to_ship do
    after_transition on: :shipped, do: :after_shipped

    event(:shipping_pending) { transition nothing_to_ship: :shipping_pending }
    event(:shipped)          { transition shipping_pending: :shipped         }
    event(:cancel_shipment)  { transition shipping_pending: :nothing_to_ship }
  end

  def mark_as_paid!
    unless paid_at
      touch(:paid_at)
    end
  end

  def available_shipping_methods
    ShippingMethod.available_for(line_items_total, shipping_address)
  end

  def item_count
    line_items.count
  end

  def add(product)
    ActiveSupport::Notifications.instrument("orders.add", product.id) do
      options = { product_id: product.id }

      if line_items.where(options).empty?
        line_items.create(options.merge(quantity: 1))
      end
    end
  end

  def update_quantity(data = {})
    data.each do |product_id, quantity|
      if line_item = line_item_for(product_id)
        line_item.update_quantity(quantity)
      end
    end
  end

  def remove(product)
    update_quantity({product.id => 0})
  end

  # Returns the total price of all line items in float.
  def line_items_total
    line_items.reduce(BigDecimal('0')) do |sum, line_item|
      sum + BigDecimal(line_item.price.to_s)
    end.round(2).to_f
  end

  def total_amount
    line_items_total + shipping_cost + tax
  end

  def total_amount_in_cents
    total_amount.to_f.round(2) * 100
  end

  def to_param
    number
  end

  def final_billing_address
    (shipping_address && !shipping_address.use_for_billing) ? billing_address : shipping_address
  end

  def initialize_addresses
    shipping_address || build_shipping_address(country_code: "US", use_for_billing: true)
    billing_address || build_billing_address(country_code: "US", use_for_billing: false)
  end

  def billing_address_same_as_shipping?
    billing_address_same_as_shipping
  end

  def line_item_for(product_id)
    line_items.find_by_product_id(product_id)
  end

  def shippable_countries
    ShippingMethod.available_for_countries(line_items_total)
  end

  private

  def set_order_number
    _number = Random.new.rand(11111111...99999999).to_s
    while self.class.exists?(number: _number) do
      _number = Random.new.rand(11111111...99999999).to_s
    end

    self.number = _number
  end

  def tax_calculator
    @_tax_calculator ||= TaxCalculator.new(self)
  end

  def shipping_cost_calculator
    @_shipping_cost_calculator ||= ShippingCostCalculator.new(self)
  end

  def after_shipped
    Mailer.delay.shipping_notification(number)
    touch(:shipped_at)
  end

end
