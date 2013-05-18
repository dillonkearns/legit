require File.expand_path('../test_helper', __FILE__)
require 'legit'
require File.expand_path('../setup_test_repo', __FILE__)

describe Legit::CLI do
  include Mocha::Integration::MiniTest

  before do
    stub_config
    Legit::CLI.any_instance.stubs(:run_command)
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
    it "calls exit 1 when TODOs staged but not disabled" do
      Legit::CLI.any_instance.expects(:todos_staged?).with('TODO').returns(true)
      Legit::CLI.any_instance.expects(:exit).with(1)
      Legit::CLI.any_instance.expects(:say).with("[pre-commit hook] Aborting commit... found staged `TODO`s.", :red)
      Legit::CLI.start('catch-todos'.split(' '))
    end

    it "doesn't call exit 1 when no TODOs staged" do
      Legit::CLI.any_instance.expects(:todos_staged?).with('TODO').returns(false)
      Legit::CLI.any_instance.expects(:exit).never
      Legit::CLI.any_instance.expects(:say).with("[pre-commit hook] Success: No `TODO`s staged.", :green)
      Legit::CLI.start('catch-todos'.split(' '))
    end

    it "removes catch-todos-mode when called with --enable" do
      config_mock = mock('config')
      config_mock.expects(:delete).with('hooks.catch-todos-mode')
      Legit::CLI.any_instance.stubs(:repo => stub({ :config => config_mock }))
      Legit::CLI.start('catch-todos --enable'.split(' '))
    end

    it "sets catch-todos-mode to disable when called with --disable" do
      config_mock = mock('config')
      config_mock.expects(:[]=).with('hooks.catch-todos-mode', 'disable')
      Legit::CLI.any_instance.stubs(:repo => stub({ :config => config_mock }))
      Legit::CLI.start('catch-todos --disable'.split(' '))
    end

    it "sets catch-todos-mode to warn when called with --warn" do
      config_mock = mock('config')
      config_mock.expects(:[]=).with('hooks.catch-todos-mode', 'warn')
      Legit::CLI.any_instance.stubs(:repo => stub({ :config => config_mock }))
      Legit::CLI.start('catch-todos --warn'.split(' '))
    end

    it "skips catch-todos when disabled" do
      stub_config('hooks.catch-todos-mode' => 'disable')
      Legit::CLI.any_instance.expects(:run_catch_todos).never
      Legit::CLI.any_instance.expects(:say).with("[pre-commit hook] ignoring todos. Re-enable with `legit catch-todos --enable`", :yellow)
      Legit::CLI.start('catch-todos'.split(' '))
    end

    it "have exit status of 0 in warn mode when positive response" do
      stub_config('hooks.catch-todos-mode' => 'warn')
      Legit::CLI.any_instance.expects(:todos_staged?).returns(true)
      Legit::CLI.any_instance.expects(:exit).never
      Legit::CLI.any_instance.expects(:yes?).with("[pre-commit hook] Found staged `TODO`s. Do you still want to continue?", :yellow).returns(true)
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

  describe "legit checkout" do
    describe "when no regex passed" do
      it "runs git checkout command" do
        Legit::CLI.any_instance.expects(:run_command).with('git checkout plain_old_branch')
        Legit::CLI.start('checkout plain_old_branch'.split(' '))
      end

      it "passes through git checkout options" do
        Legit::CLI.any_instance.expects(:run_command).with('git checkout -b plain_old_branch')
        Legit::CLI.start('checkout -b plain_old_branch'.split(' '))
      end
    end

    describe "when passed a regex" do
      before do
        setup_example_repo
      end

      it "calls checkout on branch if unique match" do
        Legit::CLI.any_instance.expects(:run_command).with('git checkout feature_with_unique_match')
        Legit::CLI.start('checkout /unique/'.split(' '))
      end

      it "calls checkout with options passed through with a unique match" do
        Legit::CLI.any_instance.expects(:run_command).with('git checkout --contains feature_with_unique_match')
        Legit::CLI.start('checkout --contains /unique/'.split(' '))
      end

      it "doesn't call checkout and exits if no match" do
        Legit::CLI.any_instance.expects(:run_command).never
        Legit::CLI.any_instance.expects(:say).with("No branches match /this_shouldnt_match_anything/", :red)
        assert_raises(SystemExit) { Legit::CLI.start('checkout /this_shouldnt_match_anything/'.split(' ')) }
      end

      it "lists options if non-unique match" do
        Legit::CLI.any_instance.expects(:run_command).never
        Legit::CLI.any_instance.expects(:ask).with(
          "Choose a branch to checkout:\n1. multiple_matches_a\n2. multiple_matches_b", :yellow).returns('2')
        Legit::CLI.any_instance.expects(:run_command).with('git checkout multiple_matches_b')
        Legit::CLI.start('checkout /multiple_matches/'.split(' '))
      end

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

def setup_example_repo
  SetupTestRepo.new.invoke(:create_repo)
  example_repo = Rugged::Repository.new(File.expand_path('../example_repo', __FILE__))
  Legit::CLI.any_instance.stubs(:repo => example_repo)
end
