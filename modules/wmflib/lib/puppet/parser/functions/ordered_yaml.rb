# == Function: ordered_yaml( mixed $data )
#
# Emit a hash as YAML with keys (both shallow and deep) in sorted order.
#
# === Examples
#
#   # Render a Puppet hash as a configuration file:
#   $options = { 'useGraphite' => true, 'minVal' => '0.1' }
#   file { '/etc/kibana/config.yaml':
#     content => ordered_yaml($options),
#   }
#
require 'puppet/util/zaml.rb'

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
      map.sort.each { |p| yield p }
    end
    value.sort.reduce(map) { |h, (k, v)| h[k] = sort_keys_recursive(v); h }
  when 'true', 'false'
    value == 'true'
  when :undef
    nil
  else
    value.include?('.') ? Float(value) : Integer(value) rescue value
  end
end

def dedent_string(string)
  lines = string.split("\n")
  return string if lines.empty?
  min_indent = lines.map { |line| line.start_with?(" ") ? line.match(/^ +/).offset(0)[1] : 0 }.min
  return string if min_indent.zero?
  lines.map { |line| line.gsub(/^ {#{min_indent}}/, "") }.join("\n")
end

module Puppet::Parser::Functions
  newfunction(:ordered_yaml, :type => :rvalue, :arity => 1) do |args|
    dedent_string(ZAML.dump(sort_keys_recursive(args.first)).gsub(/^---.*?\n/, '')) << "\n"
  end
end
