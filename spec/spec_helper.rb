require 'rubygems'
require 'bundler'

require 'rails'

Bundler.require :default, :development

Combustion.initialize! :active_record, :action_controller

require 'rspec/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
