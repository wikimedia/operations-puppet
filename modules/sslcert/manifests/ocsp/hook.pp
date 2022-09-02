# SPDX-License-Identifier: Apache-2.0
# == Define: sslcert::ocsp::hook
#
# Provisions a hook for the update-ocsp-all updater, that is going to be run
# after all OCSP responses get downloaded. This is useful in services that need
# a reload after new OCSP responses are dropped in the filesystem.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the hook will be installed. The default is 'present'.
#
# [*content*]
#   If defined, will be used as the content of the hook.
#   Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing the hook. Undefined by default.
#   Mutually exclusive with 'content'.
#
# === Examples
#
#  sslcert::ocsp::hook { 'nginx-reload':
#      content => '/bin/sh\nservice nginx reload\n',
#  }
#

define sslcert::ocsp::hook(
  Wmflib::Ensure $ensure=present,
  Optional[String] $source=undef,
  Optional[String] $content=undef,
) {
    require sslcert::ocsp::init


    file { "/etc/update-ocsp.d/hooks/${title}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => $source,
        content => $content,
    }
}
