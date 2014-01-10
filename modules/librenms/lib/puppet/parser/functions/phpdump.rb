# == Function: phpdump
#
# Serialize a hash into PHP array with lexicographically sorted keys.
#

def phpdump(o, level=1)
  indent = " "*4

  case o
  when Hash
    contents = ''
    o.sort.each do |k, v|
      contents += indent*level
      contents += "\"#{k}\" => " + phpdump(v, level+1)
      contents += ",\n"
    end
    "array(\n" + contents + indent*(level-1) + ")"
  when Array
    "array(" + o.map { |x| phpdump(x, level+1) }.join(', ') + ")"
  when TrueClass
    "TRUE"
  when FalseClass
    "FALSE"
  else
    '"' + o.to_s + '"'
  end
end

module Puppet::Parser::Functions
  newfunction(:phpdump, :type => :rvalue) do |args|
    fail 'phpdump() requires an argument' if args.empty?
    phpdump(args)
  end
end
