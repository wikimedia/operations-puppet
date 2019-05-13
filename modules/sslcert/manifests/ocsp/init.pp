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
        source => 'puppet:///modules/sslcert/update-ocsp.py',
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

    # Twice a day, 12h apart
    $cron_h12 = fqdn_rand(12, 'e663dd38dd6d3384')
    cron { 'update-ocsp-all':
        command => '/usr/local/sbin/update-ocsp-all 2>&1 | logger -t update-ocsp-all',
        minute  => fqdn_rand(60, '1adf3dd699e51805'),
        hour    => [ $cron_h12, $cron_h12 + 12 ],
        require => [
            File['/usr/local/sbin/update-ocsp-all'],
            File['/etc/update-ocsp.d'],
        ],
    }

    rsyslog::conf { 'update-ocsp-all':
        source   => 'puppet:///modules/sslcert/update-ocsp-all.rsyslog.conf',
    }

    # Rotate /var/log/update-ocsp-all.log
    logrotate::conf { 'update-ocsp-all':
        ensure => present,
        source => 'puppet:///modules/sslcert/update-ocsp-all-logrotate',
    }
}
