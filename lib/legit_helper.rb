require 'rugged'
require 'thor'

LOG_BASE_COMMAND = "git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative"

def current_branch
  system "git rev-parse --abbrev-ref HEAD"
end

def delete_local_branch!(branch_name)
  run_command("git branch -d #{branch_name}")
  $?.success?
end

def force_delete_local_branch?(branch_name)
  if yes?("Force delete branch?", :red)
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
  if yes?("Delete branch remotely?", :red)
    delete_remote_branch!(branch_name)
    true
  else
    false
  end
end

def delete_remote_branch!(branch_name)
  run_command("git push --delete origin #{branch_name}")
end

def run_command(command)
  options = {
    :verbose => ENV.has_key?('LEGIT_DEBUG')
  }
  run(command, options)
end

def todos_staged?(todo_format)
  run_command("git diff --staged | grep '^+' | grep #{todo_format}")
  $?.success?  # grep returns 0 if there is a match
end
