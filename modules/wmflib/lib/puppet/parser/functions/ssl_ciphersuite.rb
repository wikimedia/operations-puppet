# == Function: ssl_ciphersuite( string $servercode, string $encryption_type, int $hsts_days )
#
# Outputs the ssl configuration directives for use with either Nginx
# or Apache using our selection of ciphers and SSL options.
#
# === Arguments
#
# Takes three arguments:
#
# - The servercode, or which browser-version combination to
#   support. At the moment only 'apache-2.2', 'apache-2.4' and 'nginx'
#   are supported.
# - The compatibility mode,indicating the degree of compatibility we
#   want to retain with older browsers (basically, IE6, IE7 and
#   Android prior to 3.0)
# - An optional argument, that if non-nil will set HSTS to max-age of
#   N days
#
# Whenever called, this function will output a list of strings that
# can be safely used in your configuration file as the ssl
# configuration part.
#
# == Examples
#
#     ssl_ciphersuite('apache-2.4', 'compat')
#     ssl_ciphersuite('nginx', 'strong')
#
# == License
#
# Author: Giuseppe Lavagetto
# Copyright 2014 Wikimedia Foundation
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
require 'puppet/util/package'

module Puppet::Parser::Functions
  ciphersuites = {
    'compat' => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128:AES256:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!DH:!CAMELLIA',
    'strong' => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!DH:!CAMELLIA'
  }
  newfunction(
              :ssl_ciphersuite,
              :type => :rvalue,
              :doc  => <<-END
Outputs the ssl configuration part of the webserver config.
Function parameters are:
 servercode - either nginx, apache-2.2 or apache-2.4
 encryption_type - either strong for PFS only, or compat for maximum compatibility
 hsts_days  - how many days should the STS header live. If not expressed, HSTS will
              be disabled

Examples:

   ssl_ciphersuite('apache-2.4', 'compat') # Compatible config for apache 2.4
   ssl_ciphersuite('nginx', 'strong', '365') # PFS-only, use HSTS for 365 days
END
              ) do |args|


    if args.length < 2 || args.length > 3
      fail(ArgumentError, 'ssl_ciphersuite() requires at least 2 arguments')
    end

    servercode = args.shift
    case servercode
    when 'apache-2.4' then
      server = 'apache'
      server_version = 24
    when 'apache-2.2' then
      server = 'apache'
      server_version = 22
    when 'nginx' then
      server = 'nginx'
      server_version = nil
    else
      fail(ArgumentError, "ssl_ciphersuite(): unknown server string '#{servercode}'")
    end

    ciphersuite = args.shift
    unless ciphersuites.has_key?(ciphersuite)
      fail(ArgumentError, "ssl_ciphersuite(): unknown ciphersuite '#{ciphersuite}'")
    end

    cipherlist = ciphersuites[ciphersuite]

    if ciphersuite == 'strong' && server == 'apache' && server_version < 24
      fail(ArgumentError, 'ssl_ciphersuite(): apache 2.2 cannot work in strong PFS mode')
    end
    if args.length == 1
      hsts_days = args.shift.to_i
    else
      hsts_days = nil
    end

    output = []

    if server == 'apache'
      case ciphersuite
      when 'strong' then
        output.push('SSLProtocol all -SSLv2 -SSLv3 -TLSv1')
      when 'compat' then
        output.push('SSLProtocol all -SSLv2 -SSLv3')
      end
      output.push("SSLCipherSuite #{cipherlist}")
      output.push('SSLHonorCipherOrder On')
      unless hsts_days.nil?
        hsts_seconds = hsts_days * 86400
        output.push("Header set Strict-Transport-Security \"max-age=#{hsts_seconds}\"")
      end
    else
      # nginx
      case ciphersuite
      when 'strong' then
        output.push('ssl_protocols TLSv1.1 TLSv1.2;')
      when 'compat' then
        output.push('ssl_protocols TLSv1 TLSv1.1 TLSv1.2;')
      end
      output.push("ssl_ciphers #{cipherlist};")
      output.push('ssl_prefer_server_ciphers on;')
      unless hsts_days.nil?
        hsts_seconds = hsts_days * 86400
        output.push("add_header Strict-Transport-Security \"max-age=#{hsts_seconds}\";")
      end
    end
    return output
  end
end
