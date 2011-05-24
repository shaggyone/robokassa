Rails.application.routes.draw do
  controller :robokassa do
    match "robokassa/:notification_key/notify"   => :notify,  :as => :robokassa_notification
    match "robokassa/:notification_key/success"  => :success, :as => :robokassa_on_success_long
    match "robokassa/:notification_key/fail"     => :fail,    :as => :robokassa_on_fail_long

    match "robokassa/success"  => :success, :as => :robokassa_on_success
    match "robokassa/fail"     => :fail,    :as => :robokassa_on_fail
  end
end
