class Robokassa::Controller < ActionController::Base
  protect_from_forgery :only => []

  def notify
    interface = Robokassa.interface_class.create_by_notification_key params[:notification_key]
    params.delete :notification_key
    render :text => interface.notify(params, self)
  end

  def success
    retval = Robokassa.interface_class.success(params, self)
    redirect_to retval if retval.is_a? String
  end

  def fail
    retval = Robokassa.interface_class.fail(params, self)
    redirect_to retval if retval.is_a? String
  end
end