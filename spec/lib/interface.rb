require File.dirname(__FILE__) + '/../spec_helper'
require 'robokassa/interface'
describe "Interface should work correct" do
  before :each do
  end

  it "should run an error" do
    1.should == 1
    1.should_not == 2
  end

  it "should say that interface is in test mode" do
    i = ::Robokassa::Interface.new :test_mode => true
    i.should.be_test_mode?
  end

  it "should create correct init payment url" do
    
  end
end
