# SPDX-License-Identifier: Apache-2.0
# == Function: configparser_format
#
# Serialize a hash to Python ConfigParser format.
# See <http://docs.python.org/2/library/configparser.html>
#
module ConfigParser
  def self::rmerge(*args)
    # Recursively merge hashes.
    merged = args.shift.clone
    args.each do |hash|
      merged.merge!(hash) do |k, old, new|
        merged[k] = old.is_a?(Hash) && new.is_a?(Hash) ? ConfigParser.rmerge(old, new) : new
      end
    end
    merged
  end

  def self::format(config)
    # Serialize a hash to Python ConfigParser format.
    config.sort.map { |section, items|
      ["[#{section}]"].concat items.sort.map { |k, v|
        if v.is_a?(Array)
          v = v.join(',')
        else
          v = v == :undef ? '' : v
        end

        "#{k} = #{v}"
      }.push []
    }.join("\n")
  end
end

Puppet::Functions.create_function(:'graphite::configparser_format') do
  dispatch :configparser_format do
    required_repeated_param 'Hash', :args
  end
  def configparser_format(*args)
    ConfigParser.format(ConfigParser.rmerge(*args))
  end
end
