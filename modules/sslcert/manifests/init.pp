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
    package { [ 'openssl', 'ssl-cert', 'ca-certificates' ]:
        ensure => present,
    }

    exec { 'update-ca-certificates':
        command     => '/usr/sbin/update-ca-certificates',
        refreshonly => true,
        require     => Package['ca-certificates'],
    }

    # server certificates go in here; /etc/ssl/certs is a misnomer and actually
    # is just for CAs. See e.g. <https://bugs.debian.org/608719>
    file { '/etc/ssl/localcerts':
        ensure  => directory,
        owner   => 'root',
        group   => 'ssl-cert',
        mode    => '0755',
        require => Package['ssl-cert'],
    }

    # generic script for fetching the OCSP file for a given cert
    file { '/usr/local/sbin/update-ocsp':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sslcert/update-ocsp',
    }

    # install our helper that automatically creates certificate chains
    file { '/usr/local/sbin/x509-bundle':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/sslcert/x509-bundle',
    }

    # Limit AppArmor support to just Ubuntu, for now
    if $::operatingsystem == 'Ubuntu' {
        include apparmor

        # modify the default ssl_certs abstraction to support
        # /etc/ssl/localcerts, as defined above
        file { '/etc/apparmor.d/abstractions/ssl_certs':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/sslcert/apparmor/ssl_certs',
            require => Package['apparmor'],
            notify  => Service['apparmor'],
        }
    }
}
