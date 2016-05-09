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
      'Lucid'    => '10.04',
      'Maverick' => '10.10',
      'Natty'    => '11.04',
      'Oneiric'  => '11.10',
      'Precise'  => '12.04',
      'Quantal'  => '12.10',
      'Raring'   => '13.04',
      'Saucy'    => '13.10',
      'Trusty'   => '14.04',
      'Utopic'   => '14.10',
      'Vivid'    => '15.04',
      'Wily'     => '15.10',
      'Xenial'   => '16.04',
      'Yakkety'  => '16.10',
    },
    'Debian' => {
      'Wheezy'  => '7',
      'Jessie'  => '8',
      'Stretch' => '9',
      'Buster'  => '10',
    }
  }

  newfunction(:os_version, :type => :rvalue, :arity => 1) do |args|
    self_release = lookupvar('lsbdistrelease').capitalize
    self_id = lookupvar('lsbdistid').capitalize

    fail(ArgumentError, 'os_version(): string argument required') unless args.first.is_a?(String)

    clauses = args.first.split('||').map(&:strip)

    clauses.any? do |clause|
      unless /^(\w+) *([<>=]*) *([\w\.]+)$/ =~ clause
        fail(ArgumentError, "os_version(): invalid expression '#{clause}'")
      end
      # for ruby 1.8; replace with named groups with ruby >= 1.9
      other_id = Regexp.last_match(1)
      operator = Regexp.last_match(2)
      other_release = Regexp.last_match(3)

      [other_id, other_release].each(&:capitalize!)

      next unless self_id == other_id

      if os_versions[other_id].key?(other_release)
        other_was_codename = true
      end

      other_release = os_versions[other_id][other_release] || other_release

      unless /^[\d.]+$/ =~ other_release
        fail(ArgumentError,
             "os_version(): unknown #{other_id} release '#{other_release}'")
      end

      # special-case Debian point-releases, as e.g. jessie is all of 8.x
      if other_id == "Debian" && other_was_codename
        self_release = self_release.split(".")[0]
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
