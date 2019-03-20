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
end
