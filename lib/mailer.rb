require 'action_mailer'
class Mailer < ActionMailer::Base
  default({
      from: "vikrant+libs+rs+sender@webstream.io",
    })

  def error_log_email
    opts = {}
    opts[:to] = "vikrant+libs+rs+logs@webstream.io"
    opts[:subject] = "[libs.rs] error logs"
    opts[:delivery_method_options] = libs_rs_delivery_options
    opts[:body] = all_error_messages.join("\n")
    mail opts
  end

  def exception_email e
    opts = {}
    opts[:to] = "vikrant+libs+rs+exception@webstream.io"
    opts[:subject] = "[libs.rs] exception raised"
    opts[:delivery_method_options] = libs_rs_delivery_options
    opts[:body] = "#{e.class}\n"
    opts[:body] << "#{e.message}\n"
    opts[:body] << "#{e.backtrace.join("\n")}"
    mail opts
  end

  protected

  def libs_rs_delivery_options
    {
      address: Database.config.smtp.host,
      user_name: Database.config.smtp.username,
      password: Database.config.smtp.password,
    }
  end
end
