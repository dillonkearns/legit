Bundler.require(:pry) if ENV['PRY']

require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'rr'
