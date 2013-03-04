require 'colorize'
require 'rugged'

LOG_BASE_COMMAND = "git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative"

def current_branch
  system "git rev-parse --abbrev-ref HEAD"
end

def delete_local_branch!(branch_name)
  run_command("git branch -d #{branch_name}")
  $?.success?
end

def force_delete_local_branch?(branch_name)
  if yes?("Force delete branch?")
    force_delete_local_branch!(branch_name)
    true
  else
    false
  end
end

def force_delete_local_branch!(branch_name)
  run_command("git branch -D #{branch_name}")
end

def delete_remote_branch?(branch_name)
  if yes?("Delete branch remotely?")
    delete_remote_branch!(branch_name)
    true
  else
    false
  end
end

def delete_remote_branch!(branch_name)
  system("git push --delete origin #{branch_name}")
end

def run_command(command)
  show(command, :low_warning) if ENV['DEBUG']
  system(command)
end

def show(message, type = :success)
  color =
      case type
      when :success
        :green
      when :warning
        :red
      when :low_warning
        :yellow
      when :normal
        :white
      else
        raise 'Unknown prompt type'
      end

  puts message.send(color)
end

def todos_staged?(todo_format)
  run_command("git diff --staged | grep '^+' | grep #{todo_format}")
  $?.success?  # grep returns 0 if there is a match
end

def positive_response?(message, type = :normal)
  show("#{message} (y/n)", type)
  STDIN.gets.chomp =~ /y/
end
