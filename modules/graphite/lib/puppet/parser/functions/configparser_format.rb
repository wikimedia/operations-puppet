# == Function: configparser_format
#
# Serialize a hash to Python ConfigParser format.
# See <http://docs.python.org/2/library/configparser.html>
#
def configparser_format(config)
    # Serialize a hash to Python ConfigParser format
    config.sort.map { |section,items|
            ["[#{section}]"].concat items.sort.map { |k,v|
                v = case v
                when Array then v.join(',')
                when true, false then v.to_s.capitalize
                when nil, :undef, :undefined then ''
                else v
                end
                "#{k} = #{v}"
            }.push []
    }.join("\n")
end

module Puppet::Parser::Functions
    newfunction(:configparser_format, :type => :rvalue) do |args|
        if args.empty? or not args.first.is_a? Hash
            fail 'configparser_format() requires a hash argument'
        end
        configparser_format(args.first)
    end
end
