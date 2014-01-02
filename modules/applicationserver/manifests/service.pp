# applicationserver::service

class applicationserver::service {
    Class['applicationserver::apache_packages'] -> Class['applicationserver::service']
    Class['applicationserver::config::base'] -> Class['applicationserver::service']
    include mediawiki::sync

    # Start apache but not at boot
    service { 'apache':
        ensure    => running,
        name      => 'apache2',
        enable    => false,
        subscribe => Exec['mw-sync'],
        require   => Exec['mw-sync'],
    }

    # Sync the server when we see apache is not running
    exec { 'apache-trigger-mw-sync':
        command => '/bin/true',
        notify  => Exec['mw-sync'],
        unless  => '/bin/ps -C apache2 > /dev/null'
    }

    # Has to be less than apache, and apache has to be nice 0 or less to be
    # blue in ganglia.
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        file { '/etc/init/ssh.override':
            ensure  => present,
            owner   => root,
            group   => root,
            mode    => '0444',
            content => 'nice -10',
        }
    }
}
