
if Rails.env.production? || (Rails.env.staging? && Nimbleshop.config.deliver_email_for_real_in_staging)

  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    user_name: Nimbleshop.config.sendgrid.username,
    password: Nimbleshop.config.sendgrid.password,
    domain: Nimbleshop.config.sendgrid.domain,
    address: "smtp.sendgrid.net",
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }

elsif Rails.env.development? || Rails.env.staging?

  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    user_name:      Nimbleshop.config.mailtrapio.username || "nimbleshop",
    password:       Nimbleshop.config.mailtrapio.password || "7663e1f272637a4b",
    address:        "mailtrap.io",
    port:           2525,
    authentication: :plain }

end

