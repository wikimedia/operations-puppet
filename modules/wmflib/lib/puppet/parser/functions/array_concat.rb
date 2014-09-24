# == Function: array_concat( $args... )
#
# Concatenates things into an array.
# Array arguments are concatenated together
# Other types (e.g. Hashes, Strings) are included as whole single elements
#
# === Examples
#
# $a1 = [ 'a', 'b', 'c' ]
# $a2 = [ 'd', 'e' ]
# $a3 = 'f'
# $a4 = { 'g' => 'h' }
# $all = array_concat($a1, $a2, $a3, $a4)
# ### $all == [ 'a', 'b', 'c', 'd', 'e', 'f', { 'g' => 'h' } ]
#
module Puppet::Parser::Functions
  newfunction(:array_concat, :type => :rvalue) do |args|
    retval = Array.new
    args.each do |arg|
        if arg.is_a? Array
            retval += arg
        else
            retval += [ arg ]
        end
    end
    retval
  end
end
