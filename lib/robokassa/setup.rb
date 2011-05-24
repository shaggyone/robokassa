module Robokassa::Setup
  mattr_accessor :notify_lambda
  mattr_accessor :get_options_by_notifification_key_lambda

  mattr_accessor :on_success_lambda
  mattr_accessor :on_fail_lambda


  def get_options_by_notification_key(key)
    Robokassa::Setup.get_options_by_notifification_key_lambda.call(key)
  end
end
