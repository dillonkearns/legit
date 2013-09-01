require 'thor'

class SetupTestRepo < Thor
  include Thor::Actions

  desc "SOMETHING", 'something else'
  def create_repo
    test_location = File.expand_path('../example_repo', __FILE__)
    remove_dir(test_location, :verbose => false, :capture => false)
    inside(test_location) do
      run 'git init', :verbose => false, :capture => true
      run 'git config user.name "John Doe" && git config user.email johndoe@example.com', :verbose => false, :capture => true
      setup_branches
    end
  end

  private
  def setup_branches
    create_file('README.txt', 'Example repo for testing', :verbose => false, :capture => true)
    run "git add .", :verbose => false, :capture => true
    run "git commit -m 'Add README'", :verbose => false, :capture => true
    branch_names = %w{ feature_with_unique_match multiple_matches_a multiple_matches_b UPPERCASE_BRANCH }
    branch_names.each do |branch_name|
      run "git branch #{branch_name}", :verbose => false, :capture => true
    end
  end
end
