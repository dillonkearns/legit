require 'fileutils'

class TestRepo

  def self.inside(options = {}, &block)
    block_given? or raise "Must pass in block"
    repo = TestRepo.new(options[:branches])
    repo.create!
    Dir.chdir(repo.test_dir, &block)
  ensure
    repo.destroy!
  end

  def initialize(branches)
    @branches = branches || []
  end

  def create!
    FileUtils.mkdir_p(test_dir)
    FileUtils.cd(test_dir) do
      `git init`
      `git config user.name "John Doe" && git config user.email johndoe@example.com`
      setup_branches
    end
  end

  def destroy!
    FileUtils.rm_rf(test_dir)
  end

  def test_dir
    File.expand_path('../sandbox', __FILE__)
  end

  private
  def setup_branches
    File.open('README.txt', 'w') {|f| f.write("Example repo for testing\n") }
    `git add .`
    `git commit -m 'Add README'`
    @branches.each do |branch_name|
      `git branch #{branch_name}`
    end
  end
end
