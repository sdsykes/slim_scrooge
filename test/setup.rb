require 'rubygems'
gem 'activerecord', '= 2.3.5'
gem 'i18n', "= 0.3.7"
require 'active_record'
require 'active_record/connection_adapters/mysql_adapter'
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'slim_scrooge'
