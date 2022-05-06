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

# Create a binary? function to test if a file is binary or not
# https://www.ruby-forum.com/t/test-if-file-is-binary/112595
class File
  def self.binary?(name)
    ascii = control = binary = 0
    # Sample the first 1k of the file and calculate number of ascii chars
    File.open(name, 'rb') {|io| io.read(1024)}.each_byte do |byte|
      case byte
      when 0...32
        control += 1
      when 32...128
        ascii += 1
      else
        binary += 1
      end
    end
    control.to_f / ascii > 0.1 || binary.to_f / ascii > 0.05
  end
end
