# == Function: ubuntu_is
#
# === Description
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
# Release names are case-insensitive.
#
# === Examples
#
#    ubuntu_is('>= precise')  # Precise or newer
#    ubuntu_is('>= 12.04.4')  # Precise or newer
#    ubuntu_is('< utopic')    # Older than Utopic
#    ubuntu_is('> precise')   # Newer than Precise
#    ubuntu_is('<= trusty')   # Trusty or older
#    ubuntu_is('trusty')      # Exactly Trusty
#    ubuntu_is('== trusty')   # Exactly Trusty
#    ubuntu_is('!= trusty')   # Anything but Trusty
#    ubuntu_is('!trusty')     # Anything but Trusty
#
# === License
#
# Copyright 2014 Ori Livneh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
    'utopic'   => '14.10',
  }
  newfunction(
    :ubuntu_is,
    :type => :rvalue,
    :doc  => <<-END
      Performs semantic Ubuntu version comparison.
      Examples:

         ubuntu_is('>= precise')  # Precise or newer
         ubuntu_is('>= 12.04.4')  # Precise or newer
         ubuntu_is('< utopic')    # Older than Utopic
         ubuntu_is('> precise')   # Newer than Precise
         ubuntu_is('<= trusty')   # Trusty or older
         ubuntu_is('trusty')      # Exactly Trusty
         ubuntu_is('== trusty')   # Exactly Trusty
         ubuntu_is('!= trusty')   # Anything but Trusty

      Comparison target may be specified as a version number or release name.
      Release names are case-insensitive.

    END
  ) do |args|
    unless lookupvar('lsbdistid') == 'Ubuntu'
      raise Puppet::ParseError, 'ubuntu_is(): only works on Ubuntu'
    end

    expr = args.join(' ')
    unless expr =~ /^([<>=]*) *([\w\.]+)$/
      raise Puppet::ParseError, "ubuntu_is(): invalid argument '#{expr}'"
    end

    current = lookupvar('lsbdistrelease')
    operator = $1
    other = ubuntu_releases[$2.downcase] || $2
    unless /^[\d.]+$/ =~ other
      raise Puppet::ParseError, "ubuntu_is(): unknown release '#{other}'"
    end

    cmp = Puppet::Util::Package.versioncmp(current, other)
    case operator
      when nil, '', '=', '==' then cmp == 0
      when '!=', '!' then cmp != 0
      when '>' then cmp == 1
      when '<' then cmp == -1
      when '>=' then cmp >= 0
      when '<=' then cmp <= 0
      else raise Puppet::ParseError, "Unknown comparison operator: '#{operator}'"
    end
  end
end
