# mediawiki::web

class mediawiki::web ( $maxclients = '40' ) {
    include ::mediawiki

    file { '/etc/apache2/apache2.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mediawiki/apache/apache2.conf.erb'),
        require => Package['libapache2-mod-php5'],
        before  => Service['apache'],
    }

    file { '/etc/apache2/envvars':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/mediawiki/apache/envvars.appserver',
        before  => Service['apache'],
    }

    if $::realm == 'production' {
        file { '/usr/local/apache':
            ensure => directory,
        }
        exec { 'sync apache wmf config':
            require => File['/usr/local/apache'],
            path    => '/bin:/sbin:/usr/bin:/usr/sbin',
            command => 'rsync -av 10.0.5.8::httpdconf/ /usr/local/apache/conf',
            creates => '/usr/local/apache/conf',
            notify  => Service['apache']
        }
    } else {  # labs
        # bug 38996 - Apache service does not run on start, need a fake
        # sync to start it up though don't bother restarting it is already
        # running.
        exec { 'Fake sync apache wmf config on beta':
            command => '/bin/true',
            unless  => '/bin/ps -C apache2 > /dev/null',
            notify  => Service['apache'],
        }
    }

    # Start apache but not at boot
    service { 'apache':
        ensure    => running,
        name      => 'apache2',
        enable    => false,
        subscribe => Exec['mw-sync'],
        require   => [
            Exec['mw-sync'],
            File['/etc/cluster'],
        ],
    }

    # Sync the server when we see apache is not running
    exec { 'apache-trigger-mw-sync':
        command => '/bin/true',
        notify  => Exec['mw-sync'],
        unless  => '/bin/ps -C apache2 > /dev/null'
    }

    # Has to be less than apache, and apache has to be nice 0 or less to be
    # blue in ganglia.
    file { '/etc/init/ssh.override':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "nice -10\n",
    }
}
