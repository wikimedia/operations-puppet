# == Function: ssl_ciphersuite( string $server, string $encryption_type, boolean $hsts )
#
# Outputs the ssl configuration directives for use with either Nginx
# or Apache using our selection of ciphers and SSL options.
#
# === Arguments
#
# Takes three arguments:
#
# - The server to configure for: 'apache' or 'nginx'
# - The compatibility mode, trades security vs compatibility.
#   Note that due to POODLE, SSLv3 is universally disabled and none of these
#   options are compatible with SSLv3-only clients such as IE6/XP.
#   Current options are:
#   - strong:     Only TLSv1.2 with FS+AEAD ciphers.  In practice this is a
#                 very short list, and requires a very modern client.  No
#                 tradeoff is made for compatibility.  Known to work with:
#                 FF/Chrome, IE11, Safari 9, Java8, Android 4.4+, OpenSSL 1.0.x
#   - mid:        Supports TLSv1.0 and higher, and adds several forward-secret
#                 options which are not AEAD.  This is compatible with many more
#                 clients than "strong".  Should only be incompatible with
#                 unpatched IE8/XP, ancient/un-updated Java6, and some small
#                 corner cases like Nokia feature phones.
#   - compat:     Supports most legacy clients, FS optional but preferred.
# - HSTS boolean - if true, will emit our standard HSTS header for canonical
#   public domains (which is currently 1 year with preload and includeSub).
#   Default false.
#
# In our WMF configurations, Apache only supports DHE ciphersuites securely on
# Debian Jessie, which is necessary for "mid" to have the compatibility level
# stated above.  When this function is used with Apache an older host (e.g.
# Ubuntu Trusty or Precise), the "mid" and "strong" options will be downgraded
# to "compat" with a warning.
#
# Whenever called, this function will output a list of strings that
# can be safely used in your configuration file as the ssl
# configuration part.
#
# == Examples
#
#     ssl_ciphersuite('apache', 'compat', true)
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
  # 1) Mac:  AEAD > ALL       (GCM/CHACHA > CBC)
  # 2) Kx:   ECDHE > DHE      (Server Perf, may help with DH>1024 compat)
  # 3) Mac:  SHA-2 > SHA-1
  # 4) Enc:  AES128 > CHACHA > AES256
  #   ^ Note: we'd prefer [AES128, CHACHA] > AES256 here, but OpenSSL-1.1.0
  #   doesn't implement equal preference cipher grouping :(
  # 5) Auth: ECDSA > RSA      (Server Performance)
  basic = {
    # Forward-Secret + AEAD
    'strong' => [
      '-ALL',
      'ECDHE-ECDSA-AES128-GCM-SHA256',
      'ECDHE-RSA-AES128-GCM-SHA256',
      'ECDHE-ECDSA-CHACHA20-POLY1305',   # openssl-1.1.0, 1.0.2+cloudflare
      'ECDHE-RSA-CHACHA20-POLY1305',     # openssl-1.1.0, 1.0.2+cloudflare
      'ECDHE-ECDSA-CHACHA20-POLY1305-D', # 1.0.2+cloudflare
      'ECDHE-RSA-CHACHA20-POLY1305-D',   # 1.0.2+cloudflare
      'ECDHE-ECDSA-AES256-GCM-SHA384',
      'ECDHE-RSA-AES256-GCM-SHA384',
      'DHE-RSA-AES128-GCM-SHA256',
      'DHE-RSA-CHACHA20-POLY1305',   # openssl-1.1.0, 1.0.2+cloudflare
      'DHE-RSA-CHACHA20-POLY1305-D', # 1.0.2+cloudflare
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
      'DHE-RSA-AES128-SHA',
      'DHE-RSA-DES-CBC3-SHA', # openssl-1.1.0
      'EDH-RSA-DES-CBC3-SHA', # pre-1.1.0 name for the above
    ],
    # not-forward-secret compat for ancient stuff
    'compat' => [
      'AES128-SHA',   # Mostly evil proxies, also ancient devices
      'DES-CBC3-SHA', # Mostly IE7-8 on XP, also ancient devices
    ],
  }

  # Final lists exposed to callers
  ciphersuites = {
    'strong'     => basic['strong'],
    'mid'        => basic['strong'] + basic['mid'],
    'compat'     => basic['strong'] + basic['mid'] + basic['compat'],
  }

  # Our standard HSTS for all public canonical domains
  hsts_val = "max-age=31536000; includeSubDomains; preload"

  newfunction(
              :ssl_ciphersuite,
              :type => :rvalue,
              :doc  => <<-END
Outputs the ssl configuration part of the webserver config.
Function parameters are:
 server - either nginx or apache
 encryption_type - strong, mid, or compat
 hsts - optional boolean, true emits our standard public HSTS

Examples:

   ssl_ciphersuite('apache', 'compat', true) # Compatible config for apache
   ssl_ciphersuite('apache', 'mid', true) # FS-only for apache
   ssl_ciphersuite('nginx', 'strong', true) # FS-only, AEAD-only, TLSv1.2-only
END
              ) do |args|

    Puppet::Parser::Functions.function(:os_version)
    Puppet::Parser::Functions.function(:notice)

    if args.length < 2 || args.length > 3
      fail(ArgumentError, 'ssl_ciphersuite() requires at least 2 arguments')
    end

    server = args.shift
    if server != 'apache' && server != 'nginx'
      fail(ArgumentError, "ssl_ciphersuite(): unknown server string '#{server}'")
    end

    ciphersuite = args.shift
    unless ciphersuites.key?(ciphersuite)
      fail(ArgumentError, "ssl_ciphersuite(): unknown ciphersuite '#{ciphersuite}'")
    end

    do_hsts = false
    if args.length == 1
      do_hsts = args.shift
    end

    # OS / Server -dependant feature flags:
    nginx_always_ok = true
    dhe_ok = true
    if !function_os_version(['debian >= jessie'])
      nginx_always_ok = false
      if server == 'apache'
        dhe_ok = false
      end
    end

    if !dhe_ok && ciphersuite != 'compat'
      function_notice([
        'ssl_ciphersuite(): OS needs upgrade to Jessie!  Downgrading SSL ciphersuite to "compat"'
      ])
      ciphersuite = 'compat'
    end

    if dhe_ok
      cipherlist = ciphersuites[ciphersuite].join(":")
    else
      cipherlist = ciphersuites[ciphersuite].reject{|x| x =~ /^(DHE|EDH)-/}.join(":")
    end

    output = []

    if server == 'apache'
      if ciphersuite == 'strong'
        output.push('SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1')
      else
        output.push('SSLProtocol all -SSLv2 -SSLv3')
      end
      output.push("SSLCipherSuite #{cipherlist}")
      output.push('SSLHonorCipherOrder On')
      if dhe_ok
        output.push('SSLOpenSSLConfCmd DHParameters "/etc/ssl/dhparam.pem"')
      end
      if do_hsts
        output.push("Header always set Strict-Transport-Security \"#{hsts_val}\"")
      end
    else # nginx
      if ciphersuite == 'strong'
        output.push('ssl_protocols TLSv1.2;')
      else
        output.push('ssl_protocols TLSv1 TLSv1.1 TLSv1.2;')
      end
      output.push("ssl_ciphers #{cipherlist};")
      output.push('ssl_prefer_server_ciphers on;')
      if dhe_ok
        output.push('ssl_dhparam /etc/ssl/dhparam.pem;')
      end
      if do_hsts
        if nginx_always_ok
            output.push("add_header Strict-Transport-Security \"#{hsts_val}\" always;")
        else
            output.push("add_header Strict-Transport-Security \"#{hsts_val}\";")
        end
      end
    end
    return output
  end
end
