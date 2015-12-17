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
# - The compatibility mode, trades security vs compatibility.
#   Note that due to POODLE, SSLv3 is universally disabled and none of these
#   options are compatible with SSLv3-only clients such as IE6/XP.
#   Current options are:
#   - strong:     Only TLSv1.2 with PFS+AEAD ciphers.  In practice this is a
#                 very short list, and requires a very modern client.  No
#                 tradeoff is made for compatibility.  Known to work with:
#                 FF/Chrome, IE11, Safari 9, Java8, Android 4.4+, OpenSSL 1.0.x
#                 IE11 requires server-side DHE support or an ECDSA key.
#   - mid:        Supports TLSv1.0 and higher, and adds several forward-secret
#                 options which are not AEAD.  This is compatible with many
#                 more clients than "strong".  With a DHE-capable server,
#                 should only be incompatible with IE8/XP, ancient/un-updated
#                 Java6, and some small corner cases like Nokia feature
#                 phones.  With a non-DHE server, compatibility is also lost
#                 with Android 2.x, OpenSSL 0.9.8, and more Java6 clients.
#   - compat:     Supports most legacy clients, PFS optional but preferred.
# - An optional argument, that if non-nil will set HSTS to max-age of
#   N days
#
# For servers which support it (currently only nginx @ WMF), DHE cipher
# variants that are appropriate for the compatibility mode selected will be
# enabled, generally increasing forward-secrecy and compatibility, but
# sacrificing some rare/ancient/un-updated Java6 clients.
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
  # Basic list chunks, used to construct bigger lists
  # General preference ordering for fullest combined list:
  # 0) Kx:   (EC)DHE > RSA    (Forward Secrecy)
  # 1) Mac:  AEAD > ALL       (GCM > CBC)
  # 2) Kx:   ECDHE > DHE      (Server Perf, may help with DH>1024 compat)
  # 3) Mac:  SHA-2 > SHA-1
  # 4) Enc:  AES128 > AES256  (>CAMELLIA128 > CAMELLIA256)
  # 5) Auth: ECDSA > RSA      (Server Performance)
  basic = {
    # Forward-Secret + AEAD
    'strong' => [
      '-ALL',
      'ECDHE-ECDSA-AES128-GCM-SHA256',
      'ECDHE-RSA-AES128-GCM-SHA256',
      'ECDHE-ECDSA-AES256-GCM-SHA384',
      'ECDHE-RSA-AES256-GCM-SHA384',
      'DHE-RSA-AES128-GCM-SHA256',
      'DHE-RSA-AES256-GCM-SHA384',
    ],
    # Forward-Secret, but not AEAD
    'mid' => [
      'ECDHE-ECDSA-AES128-SHA256',
      'ECDHE-RSA-AES128-SHA256',
      'ECDHE-ECDSA-AES256-SHA384',
      'ECDHE-RSA-AES256-SHA384',
      'ECDHE-ECDSA-AES128-SHA',
      'ECDHE-RSA-AES128-SHA',
      'ECDHE-ECDSA-AES256-SHA',
      'ECDHE-RSA-AES256-SHA',
      'ECDHE-ECDSA-DES-CBC3-SHA',
      'ECDHE-RSA-DES-CBC3-SHA',
      'DHE-RSA-AES128-SHA256',
      'DHE-RSA-AES256-SHA256',
      'DHE-RSA-AES128-SHA',
      'DHE-RSA-AES256-SHA',
      'DHE-RSA-CAMELLIA128-SHA',
      'DHE-RSA-CAMELLIA256-SHA',
    ],
    # Only include this in "mid" for the mid-spec, because including it in
    # "compat" might block a successful negotiation by "upgrading" a working
    # compat option to a DHE-based mid option for clients that are probably
    # likely to fail on >1024-bit DHE.
    'mid-only-tail' => [
      'EDH-RSA-DES-CBC3-SHA', # EDH == DHE here, confusingly
    ],
    # not-forward-secret compat for ancient stuff
    'compat' => [
      'AES128-GCM-SHA256', # AEAD, but not forward-secret
      'AES256-GCM-SHA384', # AEAD, but not forward-secret
      'AES128-SHA256',
      'AES256-SHA256',
      'AES128-SHA',
      'AES256-SHA',
      'DES-CBC3-SHA', # Mostly IE7-8 on XP
    ],
  }

  # Final lists exposed to callers
  ciphersuites = {
    'strong'     => basic['strong'],
    'mid'        => basic['strong'] + basic['mid'] + basic['mid-only-tail'],
    'compat'     => basic['strong'] + basic['mid'] + basic['compat'],
  }

  newfunction(
              :ssl_ciphersuite,
              :type => :rvalue,
              :doc  => <<-END
Outputs the ssl configuration part of the webserver config.
Function parameters are:
 servercode - either nginx, apache-2.2 or apache-2.4
 encryption_type - strong, mid, or compat
 hsts_days  - how many days should the STS header live. If not expressed, HSTS will
              be disabled

Examples:

   ssl_ciphersuite('apache-2.4', 'compat') # Compatible config for apache 2.4
   ssl_ciphersuite('apache-2.4', 'mid') # PFS-only for apache2.4
   ssl_ciphersuite('nginx', 'strong', '365') # PFS-only, AEAD-only, TLSv1.2-only
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
    unless ciphersuites.key?(ciphersuite)
      fail(ArgumentError, "ssl_ciphersuite(): unknown ciphersuite '#{ciphersuite}'")
    end

    # Apache-2.2 has all kinds of problems with suites > compat, and should be eliminated
    #  by upgrades to trusty/jessie.
    if ciphersuite != 'compat' && server == 'apache' && server_version < 24
      fail(ArgumentError, 'ssl_ciphersuite(): apache 2.2 can only be used with "compat"')
    end

    # We can't do proper DH params for DHE suites on any of our current apache
    # builds, actually, because they weren't built against openssl-1.0.2.
    # Disabling for now, until we come up with a better way to configure this
    if server == 'apache'
      cipherlist = ciphersuites[ciphersuite].reject{|x| x =~ /^(DHE|EDH)-/}.join(":")
      set_dhparam = false
    else
      cipherlist = ciphersuites[ciphersuite].join(":")
      set_dhparam = true
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
        output.push('SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1')
      else
        output.push('SSLProtocol all -SSLv2 -SSLv3')
      end
      output.push("SSLCipherSuite #{cipherlist}")
      output.push('SSLHonorCipherOrder On')
      if set_dhparam
        output.push('SSLOpenSSLConfCmd DHParameters "/etc/ssl/dhparam.pem"')
      end
      unless hsts_days.nil?
        hsts_seconds = hsts_days * 86_400
        output.push("Header always set Strict-Transport-Security \"max-age=#{hsts_seconds}\"")
      end
    else
      # nginx
      case ciphersuite
      when 'strong' then
        output.push('ssl_protocols TLSv1.2;')
      else
        output.push('ssl_protocols TLSv1 TLSv1.1 TLSv1.2;')
      end
      output.push("ssl_ciphers #{cipherlist};")
      output.push('ssl_prefer_server_ciphers on;')
      if set_dhparam
        output.push('ssl_dhparam /etc/ssl/dhparam.pem;')
      end
      unless hsts_days.nil?
        hsts_seconds = hsts_days * 86_400
        output.push("add_header Strict-Transport-Security \"max-age=#{hsts_seconds}\";")
      end
    end
    return output
  end
end
