# == Function: apply_format( string $format, array $items )
#
# Apply a format string to each element of an array.
#
# === Examples
#
#  $languages = [ 'finnish', 'french', 'greek', 'hebrew' ]
#  $packages = apply_format('texlive-lang-%s', $languages)
#
module Puppet::Parser::Functions
  newfunction(:apply_format, :type => :rvalue, :arity => 2) do |args|
    format, *items = args
    fail(ArgumentError, 'apply_format(): a format string is required') unless format.is_a?(String)
    items.flatten.map { |item| format % item }
  end
end
