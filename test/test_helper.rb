require 'coveralls'
Coveralls.wear!

require "minitest/autorun"

require 'mocha/setup'

Bundler.require(:pry) if ENV["PRY"]
