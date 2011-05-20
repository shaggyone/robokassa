Rails.application.routes.draw do
  controller :robokassa do
    match "robokassa/:notification_key/notify"   => :notify,  :as => :robokassa_notification
    match "robokassa/:notification_key/success"  => :success, :as => :robokassa_on_success
    match "robokassa/:notification_key/fail"     => :fail,    :as => :robokassa_on_fail
  end
end
