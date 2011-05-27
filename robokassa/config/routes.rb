Rails.application.routes.draw do
  controller :robokassa do
    match "robokassa/:notification_key/notify"   => :notify,  :as => :robokassa_notification

    match "robokassa/success"  => :success, :as => :robokassa_on_success
    match "robokassa/fail"     => :fail,    :as => :robokassa_on_fail
  end
end
