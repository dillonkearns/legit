require 'colorize'

def current_branch
  system "git rev-parse --abbrev-ref HEAD"
end

def delete_remote_branch(branch_name)
  system("git push --delete origin #{branch_name}")
end

def show(message, type = :success)
  color =
      case type
      when :success
        :green
      when :warning
        :red
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
