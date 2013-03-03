require File.expand_path('../minitest_helper', __FILE__)
require 'legit'

describe Legit::CLI do
  include Mocha::Integration::MiniTest

  describe 'legit log' do
    it "parses --me command and passes through other options" do
      LOG_BASE_COMMAND = "git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative"
      args = ['log', '-p', '--me', '-n', '1']
      stub_config({ 'user.name' => 'Stubbed Username' })
      Legit::CLI.any_instance.expects(:run_command).with("#{LOG_BASE_COMMAND} --author='Stubbed Username' -p -n 1")
      Legit::CLI.start(args)
    end

    it "passes through options that aren't defined by legit log" do
      LOG_BASE_COMMAND = "git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative"
      args = ['log', '-p', '--stat']
      Legit::CLI.any_instance.expects(:run_command).with("#{LOG_BASE_COMMAND} -p --stat")
      Legit::CLI.start(args)
    end
  end
end

def stub_config(config = {})
  Legit::CLI.any_instance.stubs(:repo => stub({ :config => config }))
end
