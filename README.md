SUMMARY
-------

This gem adds robokassa support to your app.

Robokassa is payment system, that provides a single simple interface for payment systems popular in Russia.
If you have customers in Russia you can use the gem.

The first thing about this gem, is that it was oribinally desgned for spree commerce. So keep it im mind.


Using the Gem
-------------

Add the following line to your app Gemfile

    gem 'robokassa'

Update your bundle

    bundle install

Create `config/initializers/robokassa.rb` with such code

```ruby
Robokassa::Interface

module Robokassa

  def self.client
    Interface.new Interface.get_options_by_notification_key(nil)
  end

  class Interface
    class << self
      def get_options_by_notification_key(key)
        {
          test_mode: true,
          login: 'robox_login',
          password1: 'asdf1234',
          password2: 'qwer5678'
        }
      end

      def success_implementation(invoice_id, *args)
        Payment.find(invoice_id).confirm!
      end

      def fail_implementation(invoice_id, *args)
        Payment.find(invoice_id).mark_failed!
      end

      def notify_implementation(invoice_id, *args)
        Payment.find(invoice_id).verifity!
      end
    end
  end
end
```

In View file:

```ERB
<% pay_url = Robokassa.client.init_payment_url(order.id, order.amount, "Order #{order}", '', 'ru', order.user.email, {}) %>
<%= link_to "Оплатить через сервис ROBOX", pay_url %>
```

In Robokassa account settings set:

    Result URL: http://example.com/robokassa/default/notify
    Success URL: http://example.com/robokassa/success
    Fail URL: http://example.com/robokassa/fail


To overwrite controller you can do like this:

```ruby
# coding: utf-8
class RobokassaController < Robokassa::Controller
  def success
    super
    @payment = Payment.find(params[:InvId])
    redirect_to dashboard_path, notice: "Ваш платеж на сумму #{@payment.amount} руб. успешно принят. Спасибо!"
  end

  def fail
    super
    redirect_to dashboard_path, varning: "Во время принятия платежа возникла ошибка. Мы скоро разберемся!"
  end
end
```

Testing
-----
In console:

Clone gem
```bash
git clone git://github.com/shaggyone/robokassa.git
```

Install gems and generate a dummy application (It'll be ignored by git):
```bash
cd robokassa
bundle install
bundle exec combust
```

Run specs:
```bash
rake spec
```

Generate a dummy test application

Plans
-----

I plan to add generators for views
