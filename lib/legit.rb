require 'legit_helper'
require 'thor'

module Legit
  class CLI < Thor
    desc "log [ARGS]", "print a graph-like log"
    method_option :me, :type => :boolean, :desc => 'Only include my commits'
    def log(*args)
      command = []
      command << LOG_BASE_COMMAND
      command << "--author='#{repo.config['user.name']}'" if options[:me]
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

    desc "bisect BAD GOOD COMMAND", "Find the first bad commit by running COMMAND, using GOOD and BAD as the first known good and bad commits"
    def bisect(bad, good, *command_args)
      command = command_args.join(' ')
      run_command("git bisect start #{bad} #{good}")
      run_command("git bisect run #{command}")
      run_command("git bisect reset")
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
      if todos_staged?(todo_format)
        if options[:warn]
          exit 1 unless positive_response?("[pre-commit hook] Found staged `#{todo_format}`s. Do you still want to continue?", :warning)
        else
          show("[pre-commit hook] Aborting commit... found staged `#{todo_format}`s.", :warning)
          exit 1
        end
      else
        show("[pre-commit hook] Success: No `#{todo_format}`s staged.", :success)
      end
    end
  end
end
