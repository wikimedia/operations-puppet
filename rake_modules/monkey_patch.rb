# Monkey-patch PuppetSyntax and its rake task
module PuppetSyntax
  @manifests_paths = ["**/*.pp"]
  @templates_paths = ["**/*.erb"]
  class << self
    attr_accessor :manifests_paths, :templates_paths
  end
end

class PuppetSyntax::RakeTask
  def filelist_manifests
    filelist(PuppetSyntax.manifests_paths)
  end

  def filelist_templates
    filelist(PuppetSyntax.templates_paths)
  end
end

class String
  def colorize(color_code)
    "#{color_code}#{self}\033[0m"
  end

  def red
    colorize("\033[31m")
  end

  def green
    colorize("\033[32m")
  end

  def yellow
    colorize("\033[33m")
  end

  def blue
    colorize("\033[34m")
  end
end

# Add patch to test file mime type
class File
  def self.mime_type(name)
    `file -b --mime-type '#{name}'`.chomp
  end

  def self.text?(name)
    mime_type(name).split('/')[0] == 'text'
  end
end
