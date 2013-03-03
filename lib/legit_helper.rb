require 'colorize'
require 'rugged'

LOG_BASE_COMMAND = "git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative"

def current_branch
  system "git rev-parse --abbrev-ref HEAD"
end

def delete_remote_branch(branch_name)
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


def positive_response?(message, type = :normal)
  show("#{message} (y/n)", type)
  STDIN.gets.chomp =~ /y/
end
