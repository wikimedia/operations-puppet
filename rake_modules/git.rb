# Fix ruby-git deficiencies. TODO: move to rugged instead?
require 'git'

class GitOps
  # Helper class to perform the git operations we use in the rakefile
  def initialize(path)
    @git = Git.open(path)
  end

  def changes
    # Set of files that have changed between the current revision and the
    # first parent in the git tree.
    # Returns a hash with :old and :new holding lists of files
    # changed between the old revision and the new one.
    changed = {old: [], new: []}
    old = changed[:old]
    new = changed[:new]
    diffs = @git.diff('HEAD^')
    diffs.each do |diff|
      name_status = diffs.name_status[diff.path]
      case name_status
      when 'A'
        new << diff.path
      when 'C', 'M'
        new << diff.path
        old << diff.path
      when 'D'
        old << diff.path
      when /R\d+/
        old << diff.path
        regex = Regexp.new "^diff --git a/#{Regexp.escape(diff.path)} b/(.+)"
        if diff.patch =~ regex
          new << Regexp.last_match[1]
        end
      end
    end
    changed
  end

  def changes_in_head
    # Files modified in the current revision, as an array. Includes renames.
    changes[:new]
  end

  def uncommitted_changes?
    # Checks if there is any uncommitted change
    @git.diff('HEAD').size > 0
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
