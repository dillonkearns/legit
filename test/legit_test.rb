require File.expand_path('../test_helper', __FILE__)

describe Legit::CLI do
  before do
    stub_config
  end

  describe "legit log" do
    it "parses --me command and passes through other options" do
      stub_config({ 'user.name' => 'Stubbed Username' })
      flow = legit 'log -p --me -n 1', :real_repo => false
      expected = [
          [:run, "#{Legit::Helpers::LOG_BASE_COMMAND} --author='Stubbed Username' -p -n 1"]
      ]
      assert_equal expected, flow
    end

    it "passes through options that aren't defined by legit log" do
      flow = legit 'log -p --stat', :real_repo => false
      expected = [
          [:run, "#{Legit::Helpers::LOG_BASE_COMMAND} -p --stat"]
      ]
      assert_equal expected, flow
    end
  end

  describe "legit catch-todos" do
    it "calls exit 1 when TODOs staged but not disabled" do
      any_instance_of(Legit::CLI) { |cli| mock(cli).todos_staged?('TODO') { true } }
      flow = legit 'catch-todos', :real_repo => false
      expected = [
          [:say, ['[pre-commit hook] Aborting commit... found staged `TODO`s.', :red]],
          [:exit, 1],
      ]
      assert_equal expected, flow
    end

    it "doesn't call exit 1 when no TODOs staged" do
      any_instance_of(Legit::CLI) { |cli| mock(cli).todos_staged?('TODO') { false } }
      flow = legit 'catch-todos', :real_repo => false
      expected = [
          [:say, ["[pre-commit hook] Success: No `TODO`s staged.", :green]]
      ]
      assert_equal expected, flow
    end

    it "removes catch-todos-mode when called with --enable" do
      config_mock = mock(Object.new).delete('hooks.catch-todos-mode')
      stub_config(config_mock)
      flow = legit 'catch-todos --enable', :real_repo => false
      assert_equal [], flow
    end

    it "sets catch-todos-mode to disable when called with --disable" do
      config_mock = mock(Object.new).[]=('hooks.catch-todos-mode', 'disable')
      stub_config(config_mock)
      flow = legit 'catch-todos --disable', :real_repo => false
      assert_equal [], flow
    end

    it "sets catch-todos-mode to warn when called with --warn" do
      config_mock = mock(Object.new).[]=('hooks.catch-todos-mode', 'warn')
      stub_config(config_mock)
      flow = legit 'catch-todos --warn', :real_repo => false
      assert_equal [], flow
    end

    it "skips catch-todos when disabled" do
      stub_config('hooks.catch-todos-mode' => 'disable')
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).run_catch_todos.never
      end
      flow = legit 'catch-todos', :real_repo => false
      expected = [
          [:say, ["[pre-commit hook] ignoring todos. Re-enable with `legit catch-todos --enable`", :yellow]],
      ]
      assert_equal expected, flow
    end

    it "have exit status of 0 in warn mode when positive response" do
      stub_config('hooks.catch-todos-mode' => 'warn')
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).todos_staged?('TODO') { true }
        mock(cli).yes?("[pre-commit hook] Found staged `TODO`s. Do you still want to continue?", :yellow) { true }
      end

      flow = legit 'catch-todos', :real_repo => false
      assert_equal [], flow
    end
  end

  describe "legit delete" do
    it "force deletes branch when user responds yes" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { false }
        mock(cli).yes?('Force delete branch?', :red) { true }
        mock(cli).force_delete_local_branch!('branch_to_delete')
        mock(cli).delete_remote_branch?('branch_to_delete') { false }
      end

      flow = legit 'delete branch_to_delete', :real_repo => false
      assert_equal [], flow
    end

    it "doesn't force delete branch when user responds no" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { false }
        mock(cli).yes?('Force delete branch?', :red) { false }
        mock(cli).force_delete_local_branch!.never
      end
      flow = legit 'delete branch_to_delete', :real_repo => false
      assert_equal [], flow
    end

    it "deletes remotely when user responds yes" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).yes?.with('Delete branch remotely?', :red) { true }
      end
      flow = legit 'delete branch_to_delete', :real_repo => false
      expected = [
          [:run, "git branch -d branch_to_delete"],
          [:run, "git push --delete origin branch_to_delete"],
      ]
      assert_equal expected, flow
    end

    it "doesn't delete remotely when user responds no" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).delete_local_branch!('branch_to_delete') { true }
        mock(cli).yes?('Delete branch remotely?', :red) { false }
      end
      flow = legit 'delete branch_to_delete', :real_repo => false
      assert_equal [], flow
    end
  end

  describe "legit checkout" do
    before do
      @branches = %w{ feature_with_unique_match multiple_matches_a multiple_matches_b UPPERCASE_BRANCH }
    end

    it "checks out branch that matches substring" do
      flow = legit 'checkout niqu', :branches => @branches
      expected = [
          [:run, 'git checkout feature_with_unique_match'],
      ]
      assert_equal expected, flow
    end

    it "lists options if non-unique match" do
      any_instance_of(Legit::CLI) do |cli|
        mock(cli).ask("Choose a branch to checkout:\n1. multiple_matches_a\n2. multiple_matches_b", :yellow) { '2' }
      end
      flow = legit 'checkout multiple_matches', :branches => @branches
      expected = [
          [:run, 'git checkout multiple_matches_b']
      ]
      assert_equal expected, flow
    end

    it "calls checkout on branch if unique match" do
      flow = legit 'checkout unique', :branches => @branches
      expected = [
          [:run, 'git checkout feature_with_unique_match'],
      ]
      assert_equal expected, flow
    end

    it "uses case-insensitive regex" do
      flow = legit 'checkout uppercase', :branches => @branches
      expected = [
          [:run, 'git checkout UPPERCASE_BRANCH'],
      ]
      assert_equal expected, flow
    end

    it "doesn't call checkout and exits if no match" do
      flow = legit 'checkout this_shouldnt_match_anything', :branches => @branches
      expected = [
          [:say, ['No branches match /this_shouldnt_match_anything/i', :red]],
          [:exit, 1],
      ]
      assert_equal expected, flow
    end

    it "calls checkout on branch if unique match" do
      flow = legit 'checkout _wit.', :branches => @branches
      expected = [
          [:run, 'git checkout feature_with_unique_match']
      ]
      assert_equal expected, flow
    end

    it "doesn't call checkout and exits if there is no regex match" do
      flow = legit 'checkout ^_wit.', :branches => @branches
      expected = [
          [:say, ['No branches match /^_wit./i', :red]],
          [:exit, 1],
      ]
      assert_equal expected, flow
    end
  end

  describe "legit bisect" do
    it "calls the right commands" do
      command = 'ruby -n my/test/file "/testpattern/"'
      flow = legit "bisect HEAD HEAD~5 #{command}", :real_repo => false
      expected = [
          [:run, 'git bisect start HEAD HEAD~5'],
          [:run, "git bisect run #{command}"],
          [:run, 'git bisect reset'],
      ]
      assert_equal expected, flow
    end
  end
end
