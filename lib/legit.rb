require 'legit_helper'
require 'thor'

class Legit < Thor
  desc "log", "print a graph-like log"
  def log
    system("git log --pretty=format:'%C(yellow)%h%Creset%C(bold cyan)%d%Creset %s %Cgreen(%cr)%Creset %C(bold magenta) <%an>%Creset' --graph --abbrev-commit --date=relative")
  end
end
