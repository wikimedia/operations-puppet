#
# hash_deselect_re.rb
#

module Puppet::Parser::Functions
  newfunction(:hash_deselect_re, :type => :rvalue, :doc => <<-EOS
This function creates a new hash from the input hash, filtering out keys which
match the provided regex.

*Examples:*

    $in = { 'abc' => 1, 'def' => 2, 'asdf' => 3 }
    $out = hash_deselect_re('^a', $in);
    # $out == { 'def' => 2 }
    $out2 = hash_deselect_re('^(?!a)', $in);
    # $out2 == { 'abc' => 1, 'asdf' => 3 }

    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "hash_deselect_re(): Wrong number of arguments " +
      "given (#{arguments.size} for 2)") if arguments.size != 2

    pattern = Regexp.new(arguments[0])
    in_hash = arguments[1]
    unless in_hash.is_a?(Hash)
      raise(Puppet::ParseError, 'hash_deselect_re(): Argument 2 must be a hash')
    end

    # https://bibwild.wordpress.com/2012/04/12/ruby-hash-select-1-8-7-and-1-9-3-simultaneously-compatible/
    Hash[ in_hash.select { |k, _v| !pattern.match(k) } ]
  end
end

# vim: set ts=2 sw=2 et :
