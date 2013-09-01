require File.expand_path('../test_helper', __FILE__)
require 'legit'
require File.expand_path('../test_repo', __FILE__)

describe Legit::CLI do
  def expects_command(command)
    any_instance_of(Legit::CLI) { |cli| mock(cli).run_command(command) }
  end

  before do
    stub_config
    any_instance_of(Legit::CLI) do |cli|
      stub(cli).run_command
    end
  end

  describe 'legit log' do
    it "parses --me command and passes through other options" do
      stub_config({ 'user.name' => 'Stubbed Username' })
      expects_command("#{Legit::Helpers::LOG_BASE_COMMAND} --author='Stubbed Username' -p -n 1")
      legit 'log -p --me -n 1', :real_repo => false
    end

    it "passes through options that aren't defined by legit log" do
      expects_command("#{Legit::Helpers::LOG_BASE_COMMAND} -p --stat")
      legit 'log -p --stat', :real_repo => false
    end
  end

  describe 'legit catch-todos' do
    it "calls exit 1 when TODOs staged but not disabled" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).todos_staged?('TODO') { true }
        mock(cli).exit(1)
        mock(cli).say("[pre-commit hook] Aborting commit... found staged `TODO`s.", :red)
      end
      legit 'catch-todos', :real_repo => false
    end

    it "doesn't call exit 1 when no TODOs staged" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).todos_staged?('TODO') { false }
        mock(cli).exit.never
        mock(cli).say("[pre-commit hook] Success: No `TODO`s staged.", :green)
      end
      legit 'catch-todos', :real_repo => false
    end

    it "removes catch-todos-mode when called with --enable" do
      config_mock = mock(Object.new).delete('hooks.catch-todos-mode')
      stub_config(config_mock)
      legit 'catch-todos --enable', :real_repo => false
    end

    it "sets catch-todos-mode to disable when called with --disable" do
      config_mock = mock(Object.new).[]=('hooks.catch-todos-mode', 'disable')
      stub_config(config_mock)
      legit 'catch-todos --disable', :real_repo => false
    end

    it "sets catch-todos-mode to warn when called with --warn" do
      config_mock = mock(Object.new).[]=('hooks.catch-todos-mode', 'warn')
      stub_config(config_mock)
      legit 'catch-todos --warn', :real_repo => false
    end

    it "skips catch-todos when disabled" do
      stub_config('hooks.catch-todos-mode' => 'disable')
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).run_catch_todos.never
        mock(cli).say("[pre-commit hook] ignoring todos. Re-enable with `legit catch-todos --enable`", :yellow)
      end
      legit 'catch-todos', :real_repo => false
    end

    it "have exit status of 0 in warn mode when positive response" do
      stub_config('hooks.catch-todos-mode' => 'warn')
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).todos_staged?('TODO') { true }
        mock(cli).exit.never
        mock(cli).yes?("[pre-commit hook] Found staged `TODO`s. Do you still want to continue?", :yellow) { true }
      end

      legit 'catch-todos', :real_repo => false
    end
  end

  describe 'legit delete' do
    it 'force deletes branch when user responds yes' do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { false }
        mock(cli).yes?('Force delete branch?', :red) { true }
        mock(cli).force_delete_local_branch!('branch_to_delete')
        mock(cli).delete_remote_branch?('branch_to_delete') { false }
      end

      legit 'delete branch_to_delete', :real_repo => false
    end

    it "doesn't force delete branch when user responds no" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { false }
        mock(cli).yes?('Force delete branch?', :red) { false }
        mock(cli).force_delete_local_branch!.never
      end
      legit 'delete branch_to_delete', :real_repo => false
    end

    it 'deletes remotely when user responds yes' do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { true }
        mock(cli).yes?.with('Delete branch remotely?', :red) { true }
      end
      legit 'delete branch_to_delete', :real_repo => false
    end

    it "doesn't delete remotely when user responds no" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { true }
        mock(cli).yes?('Delete branch remotely?', :red) { false }
      end
      legit 'delete branch_to_delete', :real_repo => false
    end
  end

  describe "legit checkout" do
    before do
      @branches = %w{ feature_with_unique_match multiple_matches_a multiple_matches_b UPPERCASE_BRANCH }
    end

    it "checks out branch that matches substring" do
      expects_command('git checkout feature_with_unique_match')
      legit 'checkout niqu', :branches => @branches
    end

    it "lists options if non-unique match" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).run_command.never
        mock(cli).ask("Choose a branch to checkout:\n1. multiple_matches_a\n2. multiple_matches_b", :yellow) { '2' }
      end

      expects_command('git checkout multiple_matches_b')
      legit 'checkout multiple_matches', :branches => @branches
    end

    it "calls checkout on branch if unique match" do
      expects_command('git checkout feature_with_unique_match')
      legit 'checkout unique', :branches => @branches
    end

    it "uses case-insensitive regex" do
      expects_command('git checkout UPPERCASE_BRANCH')
      legit 'checkout uppercase', :branches => @branches
    end

    it "doesn't call checkout and exits if no match" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).run_command.never
        mock(cli).say("No branches match /this_shouldnt_match_anything/i", :red)
      end
      assert_raises(SystemExit) do
        legit 'checkout this_shouldnt_match_anything', :branches => @branches
      end
    end

    it "calls checkout on branch if unique match" do
      expects_command('git checkout feature_with_unique_match')
      legit 'checkout _wit.', :branches => @branches
    end

    it "doesn't call checkout and exits if there is no regex match" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).run_command.never
        mock(cli).say("No branches match /^_wit./i", :red)
      end
      assert_raises(SystemExit) do
        legit 'checkout ^_wit.', :branches => @branches
      end
    end
  end

  describe 'legit bisect' do
    it "calls the right commands" do
      command = 'ruby -n my/test/file "/testpattern/"'
      expects_command('git bisect start HEAD HEAD~5')
      expects_command("git bisect run #{command}")
      expects_command("git bisect reset")
      legit "bisect HEAD HEAD~5 #{command}", :real_repo => false
    end
  end
end
