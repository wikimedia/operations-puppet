# Fix ruby-git deficiencies. TODO: move to rugged instead?
require 'git'

class GitOps
  # Helper class to perform the git operations we use in the rakefile
  def initialize(path)
    @git = Git.open(path)
    @changed = {deleted_files: [], changed_files: [], new_files: [], rename_new: [], rename_old: []}
    process
  end

  def changes
    # Geter for changed hash
    @changed
  end

  def process
    # Process the current diff and populate @changed
    diffs = @git.diff('HEAD^')
    # Support fully ignoring paths
    data = YAML.safe_load(File.open("#{@git.dir.path}/.ignored.yaml"))
    ignored_modules = data["ignored_modules"]
    diffs.each do |diff|
      # Ignore upstream modules
      next unless ignored_modules.select { |m| %r'^modules/#{m}/' =~ diff.path }.empty?
      next if diff.path.start_with?('vendor_modules/')
      name_status = diffs.name_status[diff.path]
      case name_status
      when 'A'
        @changed[:new_files] << diff.path
      when 'C', 'M'
        @changed[:changed_files] << diff.path
      when 'D'
        @changed[:deleted_files] << diff.path
      when /R\d+/
        # This is a rename but i think its fine to also consider it a delete
        @changed[:rename_old] << diff.path
        regex = Regexp.new "^diff --git a/#{Regexp.escape(diff.path)} b/(.+)"
        if diff.patch =~ regex
          @changed[:rename_new] << Regexp.last_match[1]
        end
      end
    end
  end

  def new_files_in_head
    # Files added in the current revision, as an array. Includes renames.
    @changed[:new_files]
  end

  def changes_in_head
    # Files modified in the current revision, as an array. Includes renames.
    @changed[:changed_files] + @changed[:new_files] + @changed[:rename_new]
  end

  def changed_files_in_last
    # Produce a list of changed files that also exists in HEAD~1
    @changed[:changed_files] + @changed[:deleted_files] + @changed[:rename_old]
  end

  def uncommitted_changes?
    # Checks if there is any uncommitted change
    @git.diff('HEAD').size > 0 # rubocop:disable Style/NumericPredicate
  end

  def exec_in_rewind
    # Execs one block of code in the previous revision in git history (as defined by HEAD^)
    # And then rewinds back to the original position
    if uncommitted_changes?
      raise RunTimeError "You have local changes to the repository that would be overwritten by rewinding to a previous revision"
    end
    raise LocalJumpError "will not rollback to a previous commit with nothing to do" unless block_given?
    @git.reset_hard('HEAD^')
    yield
    @git.reset_hard('HEAD@{1}')
  end
end
