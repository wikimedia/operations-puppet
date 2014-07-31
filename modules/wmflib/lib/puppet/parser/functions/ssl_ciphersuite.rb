# == Function: ssl_ciphersuite
#
# === Description
#
# Takes two arguments: the first one indicating the degree of
# compatibility we want to retain with older browsers, the second one
# adapting the output to the specific browser.
#
# Whenever called, this function will output a two-lines string that
# can be safely included in your configuration file as the ssl
# configuration part.
#
# This is an attempt at unifying the configurations we use across our
# uncountable number of systems.
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

require 'puppet/util/package'

module Puppet::Parser::Functions
  ciphersuites = {
    'compat' => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:AES128:AES256:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!DH',
    'strong' => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!DH'
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


    if args.length < 2 && args.length > 3
      raise Puppet::ParseError, 'ssl_ciphersuite() requires at least 2 arguments'
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
    else raise Puppet::ParseError,
      "ssl_ciphersuite(): unknown server string '#{servercode}'"
    end

    ciphersuite = args.shift
    unless ciphersuites.has_key?(ciphersuite)
      raise Puppet::ParseError, "ssl_ciphersuite(): unkown ciphersuite '#{ciphersuite}'"
    end

    cipherlist = ciphersuites[ciphersuite]

    if ciphersuite == 'strong' && server == 'apache' && server_version < 24
      raise Puppet::ParseError, "ssl_ciphersuite(): apache 2.2 cannot work in strong PFS mode"
    end
    if args.length = 1
      hsts_days = args.shift.to_i
    else
      hsts_days = nil
    end

    output = ''

    if server == 'apache'
      case ciphersuite
      when 'strong' then
        output.concat("SSLProtocol all -SSLv2 -SSLv3 -TLSv1.0\n")
      when 'compat' then
        output.concat("SSLProtocol all -SSLv2\n")
      end
      output.concat("SSLCipherSuite #{cipherlist}\n")
      output.concat("SSLHonorCipherOrder On\n")
      unless hsts_days.nil?
        hsts_seconds = hsts_days * 86400
        output.concat("Header add Strict-Transport-Security \"max-age=#{hsts_seconds}\"\n")
      end
    else
      # nginx
      case ciphersuite
      when 'strong' then
        output.concat("ssl_protocols TLSv1.1 TLSv1.2;\n")
      when 'compat' then
        output.concat("ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;\n")
      end
      output.concat("ssl_ciphers #{cipherlist};\n")
      output.concat("ssl_prefer_server_ciphers on;\n")
      unless hsts_days.nil?
        hsts_seconds = hsts_days * 86400
        output.concat("add_header Strict-Transport-Security \"max-age=#{hsts_seconds}\";\n")
      end
    end
    return output
  end
end
