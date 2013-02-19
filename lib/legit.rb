require 'legit_helper'
require 'thor'

class Legit < Thor
  desc "log [ARGS]", "print a graph-like log"
  method_option :me, :type => :boolean, :desc => 'Only include my commits'
  def log(*args)
    command = []
    command << "git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative"
    command << author_equals_me if options[:me]
    args.each do |arg|
      command << arg
    end

    run_command(command.join(' '))
  end

  desc "catch-todos [TODO_FORMAT]", "Abort commit if any todos in TODO_FORMAT found"
  method_option :enable, :type => :boolean, :desc => 'Enable todo checking'
  method_option :disable, :type => :boolean, :desc => 'Disable todo checking'
  def catch_todos(todo_format = "TODO")
    if options[:enable]
      repo.config.delete('hooks.ignore-todos')
    elsif options[:disable]
      repo.config['hooks.ignore-todos'] = true
    else
      if repo.config['hooks.ignore-todos'] == 'true'
        show("[pre-commit hook] ignoring todos. Re-enable with `legit catch-todos --enable`", :low_warning)
      else
        run_catch_todos(todo_format)
      end
    end
  end

  desc "delete BRANCH", "Delete BRANCH both locally and remotely"
  def delete(branch_name)
    run_command("git branch -d #{branch_name}")

    if $?.success?
      delete_remote_branch(branch_name)
    else
      show("Force delete branch #{branch_name}? (y/n)", :warning)
      if STDIN.gets.chomp =~ /^y/
        run_command("git branch -D #{branch_name}")
        delete_remote_branch(branch_name)
      else
        puts "Abort. #{branch_name} not deleted"
      end
    end
  end

  private
  def repo
    @repo ||= Rugged::Repository.new('.')
  end

  def run_catch_todos(todo_format)
    run_command("git diff --staged | grep '^+' | grep #{todo_format}")

    if $?.success?
      if options[:warn]
        exit 1 unless positive_response?("[pre-commit hook] Found staged `#{todo_format}`s. Do you still want to continue?", :warning)
      else
        show("[pre-commit hook] Aborting commit... found staged `#{todo_format}`s.", :warning)
        exit 1
      end
    else
      show("Success: No #{todo_format}s staged.", :success)
    end
  end
end
