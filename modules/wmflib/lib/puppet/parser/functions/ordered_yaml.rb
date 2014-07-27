# == Function: ordered_yaml
#
# Emit a hash as YAML with keys in lexicographical order.
#
require 'yaml'

def prepare_value(value)
    # Prepare a value for YAML serialization by sorting the keys
    # of any hashes contained in the object.
    case value
    when Array
        value.map { |elem| prepare_value(elem) }
    when Hash
        value.sort.inject({}) { |h, (k, v)| h[k] = prepare_value(v); h }
    when 'true', 'false'
        value == 'true'
    when :undef
        nil
    else
        value.include?('.') ? Float(value) : Integer(value) rescue value
    end
end

module Puppet::Parser::Functions
    newfunction(
        :ordered_yaml,
        :type  => :rvalue,
        :arity => 1,
        :doc   => 'Emit a hash as YAML with keys in lexicographical order.'
    ) do |args|
        unless args.first.is_a?(Hash)
            raise Puppet::ParseError, 'ordered_yaml(): a hash argument is required'
        end
        prepare_value(args.first).to_yaml
    end
end
