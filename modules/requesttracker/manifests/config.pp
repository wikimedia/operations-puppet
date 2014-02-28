# sets up config files for a Wikimedia install
# of Request Tracker (RT)
class requesttracker::config {

    $rtconf = '# This file is for the command-line client, /usr/bin/rt.\n\nserver http://localhost/rt\n'

    file { '/etc/request-tracker4/RT_SiteConfig.d/50-debconf':
        require => Package['request-tracker4'],
        content => template('requesttracker/50-debconf.erb'),
        notify  => Exec['update-rt-siteconfig'];
    }

    file { '/etc/request-tracker4/RT_SiteConfig.d/51-dbconfig-common':
        require => Package['request-tracker4'],
        content => template('requesttracker/51-dbconfig-common.erb'),
        notify  => Exec['update-rt-siteconfig'];
    }

    file { '/etc/request-tracker4/RT_SiteConfig.d/80-wikimedia':
        require => Package['request-tracker4'],
        source  => 'puppet:///modules/requesttracker/80-wikimedia',
        notify  => Exec['update-rt-siteconfig'];
    }

    file { '/etc/request-tracker4/RT_SiteConfig.pm':
        require => Package['request-tracker4'],
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440';
    }

    file { '/etc/request-tracker4/rt.conf':
        require => Package['request-tracker4'],
        content => $rtconf;
    }

    exec { 'update-rt-siteconfig':
        command     => '/usr/sbin/update-rt-siteconfig-4',
        subscribe   => File[
                        '/etc/request-tracker4/RT_SiteConfig.d/50-debconf',
                        '/etc/request-tracker4/RT_SiteConfig.d/51-dbconfig-common',
                        '/etc/request-tracker4/RT_SiteConfig.d/80-wikimedia'
                        ],
        require     => Package[
                        'request-tracker4',
                        'rt4-db-mysql',
                        'rt4-clients'
                        ],
        refreshonly => true,
        notify      => Service['apache2'];
    }

}

