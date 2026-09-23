# SPDX-License-Identifier: Apache-2.0

class openstack::designate::service::flamingo
{
    $packages = [
        'designate-sink',
        'designate-common',
        'designate-mdns',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
        'python3-git',
    ]

    package { $packages:
        ensure => 'present',
    }

    file { '/etc/init.d/designate-api':
        source  => 'puppet:///modules/openstack/flamingo/designate/designate-api',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['designate-api'],
        require => Package['designate-api'];
    }

    $servicename = 'designate'
    $logfilename = 'designate-api'
    file { '/etc/designate/designate-api-uwsgi-logging.ini':
        content => template('openstack/flamingo/uwsgi/uwsgi-logging.erb'),
        notify  => Service['designate-api'],
        require => Package['designate-api'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
