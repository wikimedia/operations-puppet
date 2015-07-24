# == Function: validate_array_re( array $items, string $re )
#
# Throw an error if any member of $items does not match the regular
# expression $re.
#
# === Examples
#
#  # OK -- each array item is a four-digit number.
#  validate_array_re([8123, 8124, 8125], '^\d{4}$')
#
#  # Fail -- last array item is not a four-digit number.
#  validate_array_re([8123, 8124, 812], '^\d{4}$')
#
module Puppet::Parser::Functions
  newfunction(:validate_array_re, :arity => 2) do |args|
    items, re = args
    re = Regexp.new(re)
    invalid = args.first.find { |item| item.to_s !~ re }
    unless invalid.nil?
      fail(Puppet::ParseError, "Array element \"#{invalid}\" does not match regular expression \"#{re.source}\".")
    end
  end
end
