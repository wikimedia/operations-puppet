# SPDX-License-Identifier: Apache-2.0
# == Class: sslcert
#
# Base class to manage X.509/TLS/SSL certificates.
#
# === Parameters
#
# === Examples
#
#  include sslcert
#

class sslcert {
    ensure_packages([ 'openssl', 'ssl-cert', 'ca-certificates' ])

    exec { 'update-ca-certificates':
        command     => '/usr/sbin/update-ca-certificates',
        refreshonly => true,
        require     => Package['ca-certificates'],
    }

    # server certificates go in here; /etc/ssl/certs is a misnomer and actually
    # is just for CAs. See e.g. <https://bugs.debian.org/608719>
    $localcerts = '/etc/ssl/localcerts'
    file { $localcerts:
        ensure  => directory,
        owner   => 'root',
        group   => 'ssl-cert',
        mode    => '0755',
        require => Package['ssl-cert'],
    }

    # default permissions are 0710 which is overly restrictive; we support
    # setting $group to allow other groups to access certain keypairs
    file { '/etc/ssl/private':
        ensure  => directory,
        owner   => 'root',
        group   => 'ssl-cert',
        mode    => '0711',
        require => Package['ssl-cert'],
    }

    # install our helper that automatically creates certificate chains
    file { '/usr/local/sbin/x509-bundle':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/sslcert/x509-bundle.py',
    }
}
