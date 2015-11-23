# == Function: configparser_format
#
# Serialize a hash to Python ConfigParser format.
# See <http://docs.python.org/2/library/configparser.html>
#
def rmerge(*args)
    # Recursively merge hashes.
    merged = args.shift.clone
    args.each { |hash|
        merged.merge!(hash) { |k, old, new|
            merged[k] = old.is_a?(Hash) && new.is_a?(Hash) ? rmerge(old, new) : new
        }
    }
    return merged
end

def configparser_format(config)
    # Serialize a hash to Python ConfigParser format.
    config.sort.map { |section,items|
            ["[#{section}]"].concat items.sort.map { |k,v|
                v = v.is_a?(Array) ? v.join(',') : ( v == :undef ? '' : v )
                "#{k} = #{v}"
            }.push []
    }.join("\n")
end

module Puppet::Parser::Functions
    newfunction(:configparser_format, :type => :rvalue) { |args|
        unless args.any? && args.all? { |a| a.is_a? Hash }
            fail 'configparser_format() requires one or more hash arguments'
        end
        configparser_format(rmerge(*args))
    }
end
