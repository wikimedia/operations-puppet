class PuppetDB
  module Util
    def self.color(code)
      colors = {:red => "[31m",
                :green => "[32m",
                :yellow => "[33m",
                :cyan => "[36m",
                :bold => "[1m",
                :reset => "[0m"}

      return colors[code] || ""
    end

    def self.colorize(code, msg)
      "%s%s%s" % [ color(code), msg, color(:reset) ]
    end
  end
end
