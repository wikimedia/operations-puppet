# == Functions: ordered_json(), ordered_yaml()
#
# Emit a hash as JSON or YAML with keys (both shallow and deep) sorted
# in lexicographical order.
#
require 'json'
require 'yaml'

def sort_keys_recursive(value)
    # Prepare a value for JSON or YAML serialization by sorting its keys
    # (if it is a hash) and the keys of any hash object that is contained
    # within the value. Returns a new value.
    case value
    when Array
        value.map { |elem| sort_keys_recursive(elem) }
    when Hash
        value.sort.inject({}) { |h, (k, v)| h[k] = sort_keys_recursive(v); h }
    when 'true', 'false'
        value == 'true'
    when :undef
        nil
    else
        value.include?('.') ? Float(value) : Integer(value) rescue value
    end
end

module Puppet::Parser::Functions
    {:ordered_json => :to_json, :ordered_yaml => :to_yaml}.each do |func, method|
        newfunction(func, :type => :rvalue, :arity => 1) do |args|
            sort_keys_recursive(args.first).send(method)
        end
    end
end
