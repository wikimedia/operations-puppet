# == Function: ordered_yaml()
#
# Emit a hash as YAML with keys (both shallow and deep) in sorted order.
#
require 'yaml'

def sort_keys_recursive(value)
    # Prepare a value for YAML serialization by sorting its keys (if it is
    # a hash) and the keys of any hash object that is contained within the
    # value. Returns a new value.
    case value
    when Array
        value.map { |elem| sort_keys_recursive(elem) }
    when Hash
        map = {}

        def map.each_pair
            super.sort
        end

        value.sort.inject(map) { |h, (k, v)| h[k] = sort_keys_recursive(v); h }
    when 'true', 'false'
        value == 'true'
    when :undef
        nil
    else
        value.include?('.') ? Float(value) : Integer(value) rescue value
    end
end

module Puppet::Parser::Functions
    newfunction(:ordered_yaml, :type => :rvalue, :arity => 1) do |args|
        sort_keys_recursive(args.first).to_yaml.gsub(/^---\s*/, '') << "\n"
    end
end
