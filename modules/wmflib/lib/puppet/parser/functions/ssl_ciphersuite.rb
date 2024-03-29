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
  # Note we only support forward-secret ciphers at this point
  # General preference ordering for fullest combined list:
  # 1) Mac:  AEAD > ALL       (AES-GCM/CHAPOLY > Others)
  # 2) Auth: ECDSA > RSA      (Perf, mostly)
  # 3) Enc:  CHAPOLY > AESGCM (Old client perf, sec)
  # 4) Enc:  AES256 > AES128  (sec, batch attacks?)
  # 5) Kx:   ECDHE > DHE      (Perf, mostly)
  #
  # After all of that, the fullest list of reasonably-acceptable mid/compat
  # ciphers has been filtered further to reduce pointless clutter:
  # *) The 'mid' list has been filtered of AES256 options on the grounds that
  # any such client can always use AES128 instead, and it's senseless to try to
  # set a 'more bits' security policy if not using a strong cipher in general,
  # and clients too old for strong ciphers are more likely to be impacted by
  # AES256 performance differentials.  SHA-2 HMAC variants were filtered
  # similarly, as all clients that would negotiate x-SHA256 also negotiate x-SHA
  # and there's no effective security difference between the two.
  basic = {
    # Forward-Secret + AEAD
    'strong' => [
      '-ALL',
      'TLS_CHACHA20_POLY1305_SHA256',
      'TLS_AES_256_GCM_SHA384',
      'TLS_AES_128_GCM_SHA256',
      'ECDHE-ECDSA-CHACHA20-POLY1305',
      'ECDHE-ECDSA-AES256-GCM-SHA384',
      'ECDHE-ECDSA-AES128-GCM-SHA256',
      'ECDHE-RSA-CHACHA20-POLY1305',
      'ECDHE-RSA-AES256-GCM-SHA384',
      'ECDHE-RSA-AES128-GCM-SHA256',
    ],
    # Forward-Secret, but not AEAD
    'mid' => [
      'ECDHE-ECDSA-AES128-SHA', # Various outdated IE, Safari<9, Android<4.4
      'ECDHE-RSA-AES128-SHA',
      'DHE-RSA-AES128-SHA', # Android 2.x, openssl-0.9.8, etc
    ],
    # Currently empty, but some "mid" above may move here in later commits
    'compat' => [
    ],
  }

  # Final lists exposed to callers
  ciphersuites = {
    'strong'     => basic['strong'],
    'mid'        => basic['strong'] + basic['mid'],
    'compat'     => basic['strong'] + basic['mid'] + basic['compat'],
  }

  # Our standard HSTS for all public canonical domains
  hsts_val = "max-age=106384710; includeSubDomains; preload"

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

    Puppet::Parser::Functions.function(:notice)
    os_major_release = lookupvar('operatingsystemmajrelease').to_i

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
    tls1_3 = os_major_release > 9
    cipherlist = ciphersuites[ciphersuite].join(":")

    output = []

    if server == 'apache'
      if tls1_3
        cipherlist = ciphersuites[ciphersuite].reject{|x| x =~ /^TLS_/}.join(':')
        cipherlist_tls1_3 = ciphersuites[ciphersuite].reject{|x| x !~ /^TLS_/}.join(':')
      end
      if ciphersuite == 'compat'
        output.push('SSLProtocol all -SSLv2 -SSLv3')
      else
        output.push('SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1')
      end
      output.push("SSLCipherSuite #{cipherlist}")
      if tls1_3
        output.push("SSLCipherSuite TLSv1.3 #{cipherlist_tls1_3}")
      end
      # Note: missing config to restrict ECDH curves
      output.push('SSLHonorCipherOrder On')
      output.push('SSLOpenSSLConfCmd DHParameters "/etc/ssl/dhparam.pem"')
      if do_hsts
        output.push("Header always set Strict-Transport-Security \"#{hsts_val}\"")
      end
    else # nginx
      compat_protocols = 'TLSv1 TLSv1.1 TLSv1.2'
      protocols = 'TLSv1.2'
      if tls1_3
        compat_protocols += ' TLSv1.3'
        protocols += ' TLSv1.3'
      end
      if ciphersuite == 'compat'
        output.push("ssl_protocols #{compat_protocols};")
      else
        output.push("ssl_protocols #{protocols};")
      end
      output.push("ssl_ciphers #{cipherlist};")
      output.push("ssl_ecdh_curve X25519:prime256v1;")
      output.push('ssl_prefer_server_ciphers on;')
      output.push('ssl_dhparam /etc/ssl/dhparam.pem;')
      if do_hsts
        output.push("add_header Strict-Transport-Security \"#{hsts_val}\" always;")
      end
    end
    return output
  end
end
