module RobokassaHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::FormTagHelper
  def payment_form(interface, invoice_id, amount, description, custom_options = {})
    render 'payment_method/robokassa/init', 
      :interface      => interface,
      :invoice_id     => invoice_id,
      :amount         => amount,
      :description    => description,
      :custom_options => custom_options    
  end
end
