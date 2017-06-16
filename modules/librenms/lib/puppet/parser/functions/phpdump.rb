# == Function: phpdump
#
# Serialize a hash into PHP array with lexicographically sorted keys.
#

def phpdump(o, level = 1)
  indent = " " * 4

  case o
  when Hash
    contents = ''
    o.sort.each do |k, v|
      contents += indent * level
      contents += k.to_pson + " => " + phpdump(v, level + 1)
      contents += ",\n"
    end
    "array(\n" + contents + indent * (level - 1) + ")"
  when Array
    "array(" + o.map { |x| phpdump(x, level + 1) }.join(', ') + ")"
  when TrueClass
    "TRUE"
  when FalseClass
    "FALSE"
  when nil
    "NULL"
  else
    begin
      o.include?('.') ? Float(o).to_s : Integer(o).to_s
    rescue
      o.to_pson
    end
  end
end

module Puppet::Parser::Functions
  newfunction(:phpdump, :type => :rvalue) do |args|
    fail 'phpdump() requires an argument' if args.empty?
    fail 'phpdump() cannot handle multiple values' if args.length > 1
    phpdump(args.first)
  end
end
