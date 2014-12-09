# == Function: os_version( string $version_predicate )
#
# Performs semantic OS version comparison.
#
# Takes one or more string arguments, each containing one or more predicate
# expressions. Each expression consts of a distribution name, followed by a
# comparison operator, followed by a release name or number. Multiple clauses
# are OR'd together. The arguments are case-insensitive.
#
# The host's OS version will be compared to to the comparison target
# using the specified operator, returning a boolean. If no operator is
# present, the equality operator is assumed.
#
# === Examples
#
#  # True if Ubuntu Trusty or newer or Debian Jessie or newer
#  os_version('ubuntu >= trusty || debian >= Jessie')
#
#  # Same, but with each clause as a separate argument
#  os_version('ubuntu >= trusty', 'debian >= Jessie')
#
#  # True if exactly Debian Jessie
#  os_version('debian jessie')
#
require 'puppet/util/package'

module Puppet::Parser::Functions
  os_versions = {
    'Ubuntu' => {
      'Hardy'    => '8.04',
      'Intrepid' => '8.10',
      'Jaunty'   => '9.04',
      'Karmic'   => '9.10',
      'Lucid'    => '10.04.4',
      'Maverick' => '10.10',
      'Natty'    => '11.04',
      'Oneiric'  => '11.10',
      'Precise'  => '12.04.4',
      'Quantal'  => '12.10',
      'Raring'   => '13.04',
      'Saucy'    => '13.10',
      'Trusty'   => '14.04',
      'Utopic'   => '14.10'
    },
    'Debian' => {
      'Jessie'  => '8.0',
      'Wheezy'  => '7.0',
      'Squeeze' => '6.0',
      'Lenny'   => '5.0',
      'Etch'    => '4.0',
      'Sarge'   => '3.1',
      'Woody'   => '3.0',
      'Potato'  => '2.2',
      'Slink'   => '2.1',
      'Hamm'    => '2.0'
    }
  }

  newfunction(:os_version, :type => :rvalue, :arity => -2) do |args|
    self_release = lookupvar('lsbdistrelease').capitalize
    self_id = lookupvar('lsbdistid').capitalize

    # Multiple clauses are OR'd
    clauses = args.join('||').split('||').map(&:strip)

    clauses.any? do |clause|
      unless /^(?<other_id>\w+) *(?<operator>[<>=]*) *(?<other_release>[\w\.]+)$/ =~ clause
        fail(ArgumentError, "os_version(): invalid expression '#{clause}'")
      end

      [other_id, other_release].each(&:capitalize!)

      next unless self_id == other_id

      other_release = os_versions[other_id][other_release] || other_release

      unless /^[\d.]+$/ =~ other_release
        fail(ArgumentError,
             "os_version(): unknown #{other_id} release '#{other_release}'")
      end

      cmp = Puppet::Util::Package.versioncmp(self_release, other_release)
      case operator
      when '', '==' then cmp == 0
      when '!=' then cmp != 0
      when '>'  then cmp == 1
      when '<'  then cmp == -1
      when '>=' then cmp >= 0
      when '<=' then cmp <= 0
      else fail(ArgumentError,
                "os_version(): unknown comparison operator '#{operator}'")
      end
    end
  end
end
