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

  desc "bisect \"COMMAND\" SHAS_INCLUDED", "Git Bisect with HEAD as the bad SHA and HEAD~<SHAS_INCLUDED> as the good SHA, running your test for you with each step. If the test passes, type G <enter>. If it fails, type B <enter>. If it doesn't successfully run, type S <enter> to skip that SHA, until git displays the SHA where the test started failing. Type q <enter> to quit."
  def bisect(command = "", shas_included= "17" )
    system("git rev-parse --quiet --verify #{shas_included}") # is shas_included a valid sha?
    if $? == 0
      system("git bisect start; git bisect bad; git bisect good #{shas_included.to_s}")
    elsif shas_included.to_i.to_s == shas_included # is shas_included an integer?
      system("git bisect start; git bisect bad; git bisect good HEAD~#{shas_included.to_s}")
    else
      show("The SHA you provided doesn't seem to be in this branch. Please double check and try again.")
      system("git bisect reset")
      return
    end
    loop do
      system("#{command}")
      show("Good branch, Bad branch, Skipable branch or Quit? (g/b/s/q)")
      r = STDIN.gets.chomp
      if r =~ /^g/
        system("git bisect good")
      elsif r =~ /^b/
        system("git bisect bad")
      elsif r =~ /^s/
        system("git bisect skip")
      elsif r =~ /^q/
        system("git bisect reset")
        break
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
