# == Function: ubuntu_version( string $version_predicate )
#
# Performs semantic Ubuntu version comparison.
#
# Takes a single string argument containing a comparison operator
# followed by an optional space, followed by a comparison target,
# provided as Ubuntu version number or release name.
#
# The host's Ubuntu version will be compared to to the comparison target
# using the specified operator, returning a boolean. If no operator is
# present, the equality operator is assumed.
#
# Release names are case-insensitive. The comparison operator and
# comparison target can be provided as two separate arguments, if you
# prefer.
#
# === Examples
#
#  # True if Precise or newer
#  ubuntu_version('>= precise')
#  ubuntu_version('>= 12.04.4')
#
#  # True if older than Utopic
#  ubuntu_version('< utopic')
#
#  # True if newer than Precise
#  ubuntu_version('> precise')
#
#  # True if Trusty or older
#  ubuntu_version('<= trusty')
#
#  # True if exactly Trusty
#  ubuntu_version('trusty')
#  ubuntu_version('== trusty')
#
#  # True if anything but Trusty
#  ubuntu_version('!trusty')
#  ubuntu_version('!= trusty')
#
require 'puppet/util/package'

module Puppet::Parser::Functions
  ubuntu_releases = {
    'hardy'    => '8.04',
    'intrepid' => '8.10',
    'jaunty'   => '9.04',
    'karmic'   => '9.10',
    'lucid'    => '10.04.4',
    'maverick' => '10.10',
    'natty'    => '11.04',
    'oneiric'  => '11.10',
    'precise'  => '12.04.4',
    'quantal'  => '12.10',
    'raring'   => '13.04',
    'saucy'    => '13.10',
    'trusty'   => '14.04',
    'utopic'   => '14.10'
  }

  newfunction(:ubuntu_version, :type => :rvalue, :arity => 1) do |args|
    return false unless lookupvar('lsbdistid') == 'Ubuntu'

    unless args.length <= 2 && args.map(&:class).uniq == [String]
      fail(ArgumentError, 'ubuntu_version() requires a string argument')
    end

    expr = args.join(' ')
    unless expr =~ /^([<>=]*) *([\w\.]+)$/
      fail(ArgumentError, "ubuntu_version(): invalid expression '#{expr}'")
    end

    current = lookupvar('lsbdistrelease')
    operator = $1
    other = ubuntu_releases[$2.downcase] || $2
    unless /^[\d.]+$/ =~ other
      fail(ArgumentError, "ubuntu_version(): unknown release '#{other}'")
    end

    cmp = Puppet::Util::Package.versioncmp(current, other)
    case operator
    when '', '=', '==' then cmp == 0
    when '!=', '!' then cmp != 0
    when '>'  then cmp == 1
    when '<'  then cmp == -1
    when '>=' then cmp >= 0
    when '<=' then cmp <= 0
    else fail(ArgumentError, "ubuntu_version(): unknown comparison operator '#{operator}'")
    end
  end
end
