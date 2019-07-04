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
#  # True if Ubuntu Trusty or newer or Debian jessie or newer
#  os_version('ubuntu >= trusty || debian >= jessie')
#
#  # True if exactly Debian jessie
#  os_version('debian jessie')
#
require 'puppet/util/package'

module Puppet::Parser::Functions
  os_versions = {
    'Debian' => {
      'wheezy'  => '7',
      'jessie'  => '8',
      'stretch' => '9',
      'buster'  => '10',
    }
  }

  # minimum supported version per OS; a warning will be emitted if a comparison
  # is made against a version lower than these
  min_supported_versions = {
    'Debian' => '8',
  }

  newfunction(:os_version, :type => :rvalue, :arity => 1) do |args|
    self_release = lookupvar('lsbdistrelease')
    self_id = lookupvar('lsbdistid')

    if self_release.nil? || self_id.nil?
      fail('os_version(): LSB facts are not set; is lsb-release installed?')
    end

    unless args.first.is_a?(String)
      fail(ArgumentError, 'os_version(): string argument required')
    end

    clauses = args.first.split('||').map(&:strip)
    clauses.any? do |clause|
      unless /^(?<id>\w+) *(?<operator>[<>=]*) *(?<release>[\w\.]+)$/ =~ clause
        fail(ArgumentError, "os_version(): invalid expression '#{clause}'")
      end

      # OS names are in caps, distributions in lowercase
      other_id = id.capitalize
      other_release = release.downcase

      # if a codename was passed, get the numeric release
      if os_versions[other_id].key?(other_release)
        other_release = os_versions[other_id][other_release]
        other_was_codename = true
      elsif /^[\d.]+$/ !~ other_release
        fail(ArgumentError,
             "os_version(): unknown #{other_id} release '#{other_release}'")
      end

      # emit a warning if the release given to compare with is not supported
      min_version = min_supported_versions[other_id]
      # rubocop:disable Style/NumericPredicate
      if Puppet::Util::Package.versioncmp(other_release, min_version) < 0 ||
        (Puppet::Util::Package.versioncmp(other_release, min_version) == 0 &&
            (operator == '<=' || operator == '<'))
        message = "os_version(): obsolete distribution check in #{clause}"
      # rubocop:enable Style/NumericPredicate
        warning(message)
      end

      # skip this clause unless it's matching our operating system
      next unless self_id == other_id

      # special-case Debian point-releases, as e.g. jessie is all of 8.x
      if other_id == 'Debian' && other_was_codename
        self_release = self_release.split('.')[0]
      end

      cmp = Puppet::Util::Package.versioncmp(self_release, other_release)
      # rubocop:disable Style/NumericPredicate
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
      # rubocop:enable Style/NumericPredicate
    end
  end
end
