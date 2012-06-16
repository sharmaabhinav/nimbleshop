module NimbleshopSplitable
  module ExposedHelper

    def nimbleshop_splitable_small_image
      image_tag "engines/nimbleshop_splitable/splitable_small.png", alt: 'splitable icon'
    end

    def nimbleshop_splitable_big_image
      image_tag "engines/nimbleshop_splitable/splitable_big.png", alt: 'splitable logo'
    end

    def nimbleshop_splitable_available_payment_options_icons
      return unless NimbleshopSplitable::Splitable.first
      nimbleshop_splitable_small_image
    end

    def nimbleshop_splitable_payment_form(order)
      return unless NimbleshopSplitable::Splitable.first
      render partial: '/nimbleshop_splitable/payments/new', locals: {order: order}
    end

    def nimbleshop_splitable_crud_form
      return unless NimbleshopSplitable::Splitable.first
      render partial: '/nimbleshop_splitable/splitables/edit'
    end

    def nimbleshop_splitable_icon_for_order_payment(order)
      nimbleshop_splitable_small_image
    end

  end
end
