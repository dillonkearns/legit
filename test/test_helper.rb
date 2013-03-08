require 'coveralls'
Coveralls.wear!

require "minitest/autorun"
require "minitest/reporters"

# for attaching tests to rubymine
MiniTest::Reporters.use! if ENV['RUBYMINE']

require 'mocha/setup'
