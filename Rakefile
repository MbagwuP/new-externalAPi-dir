# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
# 
require 'rubygems'
require 'bundler'

Bundler.require
require 'rake'

# # Required for foreigner gem. Remove this (and foreigner gem) after upgrade to ActiveRecord 4.2
# ActiveSupport.on_load :active_record do
#   Foreigner.load
# end

require File.expand_path('../app/main.rb', __FILE__)
require File.expand_path('../config/initializers/external_api.rb', __FILE__)

Dir.glob('lib/tasks/*.rake').each { |rke| import rke }

task :environment, [:environment] do |t, args| 
  args.with_defaults(:environment => 'development')
end
