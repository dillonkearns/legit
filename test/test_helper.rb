Bundler.require(:pry) if ENV['PRY']

require 'legit'
require File.expand_path('../test_repo', __FILE__)

require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'rr'

require 'thor'
# silence warnings for mocks
class Thor
  def self.create_command(meth) #:nodoc:
    if @usage && @desc
      base_class = @hide ? Thor::HiddenCommand : Thor::Command
      commands[meth] = base_class.new(meth, @desc, @long_desc, @usage, method_options)
      @usage, @desc, @long_desc, @method_options, @hide = nil
      true
    elsif self.all_commands[meth] || meth == "method_missing"
      true
    else
      #puts "[WARNING] Attempted to create command #{meth.inspect} without usage or description. " <<
      #         "Call desc if you want this method to be available as command or declare it inside a " <<
      #         "no_commands{} block. Invoked from #{caller[1].inspect}."
      false
    end
  end
end

def legit(command, options = {})
  fake_repo = options.delete(:fake_repo)
  if fake_repo
    capture_legit_output(command)
  else
    TestRepo.inside(options) { capture_legit_output(command) }
  end
end

def stub_config(config = {})
  any_instance_of(Rugged::Repository) do |repo|
    stub(repo).config { config }
  end
end

def capture_legit_output(command)
  flow = []
  any_instance_of(Legit::CLI) do |cli|
    stub(cli).run { |cmd, options| flow << [:run, cmd] }   # throw away options; only used for verbosity in debug mode
    stub(cli).say { |*args| flow << [:say, args] }
    stub(cli).exit do |code|
      flow << [:exit, code]
      exit code   # must call exit manually instead of using proxy or it will exit before it captures the flow
    end
  end
  begin
    Legit::CLI.start(command.split(' '))
  rescue SystemExit
    # exit stops the thor command, but not the test runner
  end
  flow
end
