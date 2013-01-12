require 'legit_helper'
require 'thor'

class Legit < Thor
  desc "log", "print a graph-like log"
  def log
    system("git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative")
  end

  desc "catch-todos [TODO_FORMAT]", "Abort commit if any todos in TODO_FORMAT found"
  def catch_todos(todo_format = "TODO")
    system("git diff --staged | grep '^+' | grep #{todo_format}")

    if $?.success?
      show("[pre-commit hook] Aborting commit... found staged `#{todo_format}`s.", :warning)
      exit 1
    else
      show("Success: No #{todo_format}s staged.", :success)
    end
  end

  desc "delete BRANCH", "Delete BRANCH both locally and remotely"
  def delete(branch_name)
    system("git branch -d #{branch_name}")

    if $?.success?
      delete_remote_branch(branch_name)
    else
      show("Force delete branch #{branch_name}? (y/n)", :warning)
      if STDIN.gets.chomp =~ /^y/
        system("git branch -D #{branch_name}")
        delete_remote_branch(branch_name)
      else
        puts "Abort. #{branch_name} not deleted"
      end
    end
  end

end
