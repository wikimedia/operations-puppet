# == Function: ordered_json
#
# Serialize a hash into JSON with lexicographically sorted keys.
#
# Because the order of keys in Ruby 1.8 hashes is undefined, 'to_pson'
# is not idempotent: i.e., the serialized form of the same hash object
# can vary from one invocation to the next. This causes problems
# whenever a JSON-serialized hash is included in a file template,
# because the variations in key order are picked up as file updates by
# Puppet, causing Puppet to replace the file and refresh dependent
# resources on every run.
#
def ordered_json(o)
    case o
    when Array
        '[' + o.map { |x| ordered_json(x) }.join(', ') + ']'
    when Hash
        '{' + o.sort.map { |k,v| k.to_pson + ': ' + ordered_json(v) }.join(', ') + '}'
    else
        o.include?('.') ? Float(o).to_s : Integer(o).to_s rescue o.to_pson
    end
end

module Puppet::Parser::Functions
    newfunction(:ordered_json, :type => :rvalue) do |args|
        fail 'ordered_json() requires an argument' if args.empty?
        ordered_json(args.inject(:merge))
    end
end
