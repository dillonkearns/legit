require File.expand_path('../test_helper', __FILE__)
require 'legit'

describe Legit::CLI do
  include Mocha::Integration::MiniTest

  before do
    stub_config
  end

  describe 'legit log' do
    it "parses --me command and passes through other options" do
      args = 'log -p --me -n 1'
      stub_config({ 'user.name' => 'Stubbed Username' })
      Legit::CLI.any_instance.expects(:run_command).with("#{LOG_BASE_COMMAND} --author='Stubbed Username' -p -n 1")
      Legit::CLI.start(args.split(' '))
    end

    it "passes through options that aren't defined by legit log" do
      args = 'log -p --stat'
      Legit::CLI.any_instance.expects(:run_command).with("#{LOG_BASE_COMMAND} -p --stat")
      Legit::CLI.start(args.split(' '))
    end
  end

  describe 'legit catch-todos' do
    it "calls exit 1 when TODOs staged but not when disabled" do
      Legit::CLI.any_instance.expects(:todos_staged?).with('TODO').returns(true)
      Legit::CLI.any_instance.expects(:exit).with(1)
      Legit::CLI.any_instance.expects(:show).with("[pre-commit hook] Aborting commit... found staged `TODO`s.", :warning)
      Legit::CLI.start(['catch-todos'])

      Legit::CLI.start('catch-todos --disable'.split(' '))
      Legit::CLI.any_instance.expects(:exit).never
    end

    it "doesn't call exit 1 when no TODOs staged" do
      Legit::CLI.any_instance.expects(:todos_staged?).with('TODO').returns(false)
      Legit::CLI.any_instance.expects(:exit).never
      Legit::CLI.any_instance.expects(:show).with("[pre-commit hook] Success: No `TODO`s staged.", :success)
      Legit::CLI.start('catch-todos'.split(' '))
    end
  end

  describe 'legit delete' do
    it 'force deletes branch when user responds yes' do
      Legit::CLI.any_instance.expects(:delete_local_branch!).with('branch_to_delete').returns(false)
      Legit::CLI.any_instance.expects(:yes?).with('Force delete branch?', :red).returns(true)
      Legit::CLI.any_instance.expects(:force_delete_local_branch!).with('branch_to_delete')
      Legit::CLI.any_instance.expects(:delete_remote_branch?).with('branch_to_delete').returns(false)
      Legit::CLI.start('delete branch_to_delete'.split(' '))
    end

    it "doesn't force delete branch when user responds no" do
      Legit::CLI.any_instance.expects(:delete_local_branch!).with('branch_to_delete').returns(false)
      Legit::CLI.any_instance.expects(:yes?).with('Force delete branch?', :red).returns(false)
      Legit::CLI.any_instance.expects(:force_delete_local_branch!).never
      Legit::CLI.start('delete branch_to_delete'.split(' '))
    end

    it 'deletes remotely when user responds yes' do
      Legit::CLI.any_instance.expects(:delete_local_branch!).with('branch_to_delete').returns(true)
      Legit::CLI.any_instance.expects(:yes?).with('Delete branch remotely?', :red).returns(true)
      Legit::CLI.start('delete branch_to_delete'.split(' '))
    end

    it "doesn't delete remotely when user responds no" do
      Legit::CLI.any_instance.expects(:delete_local_branch!).with('branch_to_delete').returns(true)
      Legit::CLI.any_instance.expects(:yes?).with('Delete branch remotely?', :red).returns(false)
      Legit::CLI.start('delete branch_to_delete'.split(' '))
    end
  end

  describe 'legit bisect' do
    command = 'ruby -n my/test/file "/testpattern/"'
    args = "bisect HEAD HEAD~5 #{command}"
    Legit::CLI.any_instance.expects(:run_command).with('git bisect start HEAD HEAD~5')
    Legit::CLI.any_instance.expects(:run_command).with("git bisect run #{command}")
    Legit::CLI.any_instance.expects(:run_command).with("git bisect reset")
    Legit::CLI.start(args.split(' '))
  end
end

def stub_config(config = {})
  Legit::CLI.any_instance.stubs(:repo => stub({ :config => config }))
end
