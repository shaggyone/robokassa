require File.dirname(__FILE__) + '/../spec_helper'
require 'robokassa/interface'
describe "Interface should work correct" do
  before :each do
  end
  
  it "Should correctly use test server" do
    i = Robokassa::Interface.new :test_mode => true
    i.should be_test_mode
    i.base_url.should == "http://test.robokassa.ru"
  end

  it "should compute correct signature string" do
    i = Robokassa::Interface.new :test_mode => true, :login => 'demo', 'password1' => '12345'
    i.init_payment_signature_string(15, 185.0, "Order #125").should == "demo:185.0:15:12345"
    i.init_payment_signature_string(15, 185.0, "Order #125", {:a => 15, :c => 30, :b => 20}).should == "demo:185.0:15:12345:shpa=15:shpb=20:shpc=30"
  end

  it "should create correct init payment url" do
    i = Robokassa::Interface.new :test_mode => true, :login => 'demo', 'password1' => '12345'
    i = Robokassa::Interface.new :test_mode => true, :login => 'shaggyone239', 'password1' => '12345asdf' 
    i.init_payment_signature_string(15, 185.11, "Order #125").should == "shaggyone239:185.11:15:12345asdf"
    i.init_payment_signature(15, 185.11, "Order #125").should == "55f2aee20767cde28e7fc49919cec969"
    i.init_payment_url(15, 185.11, "Order 125", '', 'ru', 'demo@robokassa.ru', {}).should == 
      "http://test.robokassa.ru/Index.aspx?MrchLogin=shaggyone239&OutSum=185.11&InvId=15&Desc=Order+125&SignatureValue=55f2aee20767cde28e7fc49919cec969&IncCurrLabel=&Email=demo%40robokassa.ru&Culture=ru"
    i.init_payment_signature(196, 2180.0, "R602412577").should == "adeedf2afbac5eca09b44898da3ef51a"
  end

  it "should return correct notification, success and fail urls" do
    i = Robokassa::Interface.new :test_mode => true, :login => 'demo', 'password1' => '12345', :notification_key => "asfadsf"
    i.default_url_options = {
      :host => '127.0.0.1',
      :port => 3000
    }
    i.notification_url.should == 'http://127.0.0.1:3000/robokassa/asfadsf/notify'
    i.on_success_url.should == 'http://127.0.0.1:3000/robokassa/success'
    i.on_fail_url.should == 'http://127.0.0.1:3000/robokassa/fail'
  end
end
