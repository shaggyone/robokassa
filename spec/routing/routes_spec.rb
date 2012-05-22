require 'spec_helper'


describe 'routes' do
  context "robokassa" do
    specify { get('/robokassa/some-secure-notification-key/notify').should route_to(
      controller:       'robokassa',
      action:           'notify',
      notification_key: 'some-secure-notification-key'
    )}

    specify { get('/robokassa/success').should route_to(
      controller: 'robokassa',
      action:     'success'
    )}

    specify { get('/robokassa/fail').should route_to(
      controller: 'robokassa',
      action:     'fail'
    )}
  end
end

