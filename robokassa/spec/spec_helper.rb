$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../../test_app/config/application", __FILE__)
require File.expand_path("../../config/routes", __FILE__)

require 'rspec/rails'  

require 'rails/all'
require 'fileutils'
require 'rubygems'
require 'bundler'
require 'rspec'

#$show_err = true
#$debug    = false


RSpec.configure do |config|
  config.before :all do
  end

  config.before :each do
  end

  config.after :each do
  end
end
