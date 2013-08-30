require 'legit/helpers'

module Legit
  class CLI < Thor
    include Thor::Actions
    include Legit::Helpers

    desc "log [ARGS]", "print a graph-like log"
    method_option :me, :type => :boolean, :desc => 'Only include my commits'
    def log(*args)
      command = []
      command << Legit::Helpers::LOG_BASE_COMMAND
      command << "--author='#{repo.config['user.name']}'" if options[:me]
      args.each do |arg|
        command << arg
      end

      run_command(command.join(' '))
    end

    desc "catch-todos [TODO_FORMAT]", "Abort commit if any todos in TODO_FORMAT found"
    method_option :enable, :type => :boolean, :desc => 'Enable todo checking'
    method_option :disable, :type => :boolean, :desc => 'Disable todo checking'
    method_option :warn, :type => :boolean, :desc => 'Turn on warn mode'
    def catch_todos(todo_format = "TODO")
      if options[:enable]
        repo.config.delete('hooks.catch-todos-mode')
      elsif options[:disable]
        repo.config['hooks.catch-todos-mode'] = 'disable'
      elsif options[:warn]
        repo.config['hooks.catch-todos-mode'] = 'warn'
      else
        if repo.config['hooks.catch-todos-mode'] == 'disable'
          say("[pre-commit hook] ignoring todos. Re-enable with `legit catch-todos --enable`", :yellow)
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

    desc "checkout ARGS", "git checkout, matching an arg between /'s to a local branch, i.e. `legit checkout /my_feature/`"
    def checkout(*args)
      regex_index = args.index { |arg| arg =~ %r{\A/.*/\z} }

      if regex_index
        regex_argument = args.delete_at(regex_index)
        regex_without_slashes = regex_argument[%r{\A/(.*)/\z}, 1]
        regex = Regexp.new(regex_without_slashes)

        local_branches = repo.branches.select { |b| b.branch? }
        matching_branches = local_branches.select { |b| b.name =~ regex }

        matched_branch =
            case matching_branches.length
            when 0
              say("No branches match #{regex.inspect}", :red)
              exit 1
            when 1
              matching_branches.first
            else
              matching_branches = matching_branches.sort_by {|b| b.name }
              branch_list = matching_branches.each_with_index.map { |branch, index| "#{index + 1}. #{branch.name}"}
              response = ask("Choose a branch to checkout:\n#{branch_list.join("\n")}", :yellow).to_i
              matching_branches[response - 1]
            end
        args.insert(regex_index, matched_branch.name)
      end

      run_command("git checkout #{args.join(' ')}")
    end

    desc "delete BRANCH", "Delete BRANCH both locally and remotely"
    def delete(branch_name)
      delete_local_branch!(branch_name) || force_delete_local_branch?(branch_name) and delete_remote_branch?(branch_name)
    end

    private
    def repo
      @repo ||= Rugged::Repository.new(Rugged::Repository.discover)
    end

    def run_catch_todos(todo_format)
      if todos_staged?(todo_format)
        if repo.config['hooks.catch-todos-mode'] == 'warn'
          exit 1 unless yes?("[pre-commit hook] Found staged `#{todo_format}`s. Do you still want to continue?", :yellow)
        else
          say("[pre-commit hook] Aborting commit... found staged `#{todo_format}`s.", :red)
          exit 1
        end
      else
        say("[pre-commit hook] Success: No `#{todo_format}`s staged.", :green)
      end
    end
  end
end
