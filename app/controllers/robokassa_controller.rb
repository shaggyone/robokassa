class RobokassaController < ActionController::Base
  protect_from_forgery :only => []

  def notify
#    begin
      i = Robokassa::Interface.create_by_notification_key params[:notification_key]
      params.delete :notification_key
      render :text => i.notify(params)
#    rescue Exception => e
#      render :text => e.to_s
#    end
  end

  def success
      i = params[:notification_key] ? Robokassa::Interface.create_by_notification_key(params[:notification_key]) : nil
      params.delete :notification_key
      retval = Robokassa::Interface.success(i, params)
      redirect_to retval if retval.is_a? String
  end

  def fail
      i = params[:notification_key] ? Robokassa::Interface.create_by_notification_key(params[:notification_key]) : nil
      params.delete :notification_key
      retval = Robokassa::Interface.fail(i, params)
      redirect_to retval if retval.is_a? String
  end
end
