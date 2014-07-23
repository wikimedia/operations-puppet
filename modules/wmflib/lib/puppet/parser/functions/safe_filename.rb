# == Function: safe_filename
#
# === Description
#
# Generates a well-formed, filesystem-safe file name from its arguments.
#
# Steps:
# * Cast each argument to string.
# * Join arguments with a dash.
# * Convert to lowercase.
# * Replace non-alphanumeric characters with dashes.
# * Trim leading and trailing dashes from each dot-separated component.
# * Pad single-digit priority prefix with a leading zero.
#
# === Examples
#
#  safe_filename('Config::File')           # => 'config-file'
#  safe_filename('config::file', '.cfg!')  # => 'config-file.cfg'
#  safe_filename('6', 'apache-site.conf')  # => '06-apache-site.conf'
#
module Puppet::Parser::Functions
  newfunction(
    :safe_filename,
    :type => :rvalue,
    :doc  => <<-END
      Generates a well-formed, filesystem-safe file name from its arguments.

      Steps:
      * Cast each argument to string.
      * Join arguments with a dash.
      * Convert to lowercase.
      * Replace non-alphanumeric characters with dashes.
      * Trim leading and trailing dashes from each dot-separated component.
      * Pad single-digit priority prefix with a leading zero.

      Examples:

        safe_filename('Config::File')           # => 'config-file'
        safe_filename('config::file', '.cfg!')  # => 'config-file.cfg'
        safe_filename('6', 'apache-site.conf')  # => '06-apache-site.conf'

    END
  ) do |args|
    if args.empty?
      raise Puppet::ParseError, 'safe_filename(): one or more arguments required'
    end

    safe = args
      .map(&:to_s)
      .join('-')
      .downcase
      .gsub(/[^a-z0-9.]+/, '-')
      .split('.')
      .map { |chunk| chunk.gsub(/^-|-$/, '') }
      .join('.')
    safe.prepend('0') if safe =~ /^\d-/

    if safe.empty?
      raise Puppet::ParseError, 'safe_filename(): args contain no valid characters'
    end

    return safe
  end
end
