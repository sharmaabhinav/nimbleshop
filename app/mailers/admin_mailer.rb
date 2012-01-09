class AdminMailer < ActionMailer::Base
  include ApplicationHelper

  default :from => Settings.from_email
  default_url_options[:host] = Settings.host_for_email
  default_url_options[:protocol] = 'http'

  def shipping_notification(order_number)
    subject = "Items for order ##{order_number} have been shipped"
    @order = Order.find_by_number!(order_number)

    mail_options = {:to => @order.email, :subject => subject}
    mail(mail_options) do |format|
      format.text { render "admin/mailer/shipping_notification" }
    end
  end

  def new_order_notification(order_number)
    subject = "Order ##{order_number} was recetly placed"
    @order = Order.find_by_number!(order_number)

    # TODO ideally I should be able to use current_shop below
    @shop = Shop.first
    @payment_date = @order.creditcard_transactions.first.created_at.to_s(:long)
    @creditcard_masked_number = @order.creditcard_transactions.first.creditcard.masked_number

    mail_options = {:to => @order.email, :subject => subject}
    mail(mail_options) do |format|
      format.text { render "admin/mailer/new_order_notification" }
    end

  end

end