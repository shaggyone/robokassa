require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rubygems/package_task'
require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

desc "Default Task"
task :default => [:spec]
