Bundler.require(:pry) if ENV['PRY']

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

def legit(command, real_repo = true)
  run_command = Proc.new { Legit::CLI.start(command.split(' ')) }
  if real_repo
    TestRepo.inside(&run_command)
  else
    run_command.call
  end
end
