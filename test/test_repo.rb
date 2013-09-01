require 'fileutils'

module TestRepo

  def self.inside(&block)
    block_given? or raise "Must pass in block"
    create!
    Dir.chdir(test_dir, &block)
  ensure
    destroy!
  end

  private
  def self.test_dir
    File.expand_path('../sandbox', __FILE__)
  end

  def self.create!
    FileUtils.mkdir_p(test_dir)
    FileUtils.cd(test_dir) do
      `git init`
      `git config user.name "John Doe" && git config user.email johndoe@example.com`
      setup_branches
    end
  end

  def self.destroy!
    FileUtils.rm_rf(test_dir)
  end

  def self.setup_branches
    File.open('README.txt', 'w') {|f| f.write("Example repo for testing\n") }
    `git add .`
    `git commit -m 'Add README'`
    branch_names = %w{ feature_with_unique_match multiple_matches_a multiple_matches_b UPPERCASE_BRANCH }
    branch_names.each do |branch_name|
      `git branch #{branch_name}`
    end
  end
end
