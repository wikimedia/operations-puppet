# == Class: sslcert::ocsp::init
#
# Base class for the OCSP stapler scripts.
#
# === Parameters
#
# === Examples
#
#  include sslcert::ocsp::init
#
class sslcert::ocsp::init {
    require sslcert

    # generic script for fetching the OCSP file for a given cert
    file { '/usr/local/sbin/update-ocsp':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/sslcert/update-ocsp',
    }

    file { '/usr/local/sbin/update-ocsp-all':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/sslcert/update-ocsp-all',
    }

    file { '/etc/update-ocsp.d':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/update-ocsp.d/hooks':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/var/cache/ocsp':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    cron { 'update-ocsp-all':
        command => '/usr/local/sbin/update-ocsp-all >> /var/log/update-ocsp-all.log 2>&1',
        minute  => fqdn_rand(60, '1adf3dd699e51805'),
        hour    => '*',
        require => [
            File['/usr/local/sbin/update-ocsp-all'],
            File['/etc/update-ocsp.d'],
        ],
    }

    # Rotate /var/log/update-ocsp-all.log
    logrotate::conf { 'update-ocsp-all':
        ensure => present,
        source => 'puppet:///modules/sslcert/update-ocsp-all-logrotate',
    }
}
