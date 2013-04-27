class ceph::radosgw(
    $servername='localhost',
    $serveradmin='webmaster@localhost',
) {
    Class['ceph'] -> Class['ceph::radosgw']

    package { [ 'radosgw', 'radosgw-dbg' ]:
        ensure => present,
    }

    file { '/var/lib/ceph/radosgw/ceph-radosgw':
        ensure  => directory,
        owner   => 'root'   ,
        group   => 'root',
        require => Package['radosgw'],
    }
    file { '/var/lib/ceph/radosgw/ceph-radosgw/done':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        require => File['/var/lib/ceph/radosgw/ceph-radosgw'],
    }

    service { 'radosgw id=radosgw':
        ensure     => 'running',
        status     => '/sbin/status radosgw id=radosgw',
        start      => '/sbin/start  radosgw id=radosgw',
        stop       => '/sbin/stop   radosgw id=radosgw',
        restart    => '/sbin/start  radosgw id=radosgw',
        hasrestart => true,
        provider   => 'upstart',
        require    => File['/var/lib/ceph/radosgw/ceph-radosgw/done'],
    }

    $id = 'client.radosgw'
    $keyfname = "/etc/ceph/ceph.${id}.keyring"
    exec { "ceph auth ${id}":
        command  => "/usr/bin/ceph \
                    auth get-or-create \
                    ${id} \
                    mon 'allow r' osd 'allow rwx' > ${keyfname}",
        creates  => $keyfname,
    }

    # for <= bobtail, http://tracker.newdream.net/issues/3813
    file { '/etc/logrotate.d/radosgw':
        ensure => present,
        source => 'puppet:///modules/ceph/logrotate-radosgw',
        owner   => 'root',
        group   => 'root',
    }

    # install apache + fastcgi + rewrite. fcgid doesn't stream
    # the standard apache module is crap really, so this isn't great
    class { 'apache':
        default_mods => false,
        serveradmin  => $serveradmin,
    }
    package { 'libapache2-mod-fastcgi':
        ensure => present,
        require => Package['apache2'],
        notify  => Service['apache2'],
    }
    file { '/etc/apache2/mods-enabled/rewrite.load':
        ensure  => link,
        target  => '../mods-available/rewrite.load',
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    # VirtualHost config
    file { '/etc/apache2/sites-available/radosgw':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('ceph/radosgw/vhost.erb'),
        require => Package['apache2'],
        notify  => Service['apache2'],
    }
    file { '/etc/apache2/sites-enabled/radosgw':
        ensure  => link,
        target  => '../sites-available/radosgw',
        require => File['/etc/apache2/sites-available/radosgw'],
        notify  => Service['apache2'],
    }
    file { '/etc/apache2/sites-enabled/000default':
        ensure  => absent,
        require => Package['apache2'],
        notify  => Service['apache2'],
    }

    # just a simple file to be able to do health checks on Apache
    # /monitoring/backend also exists but is routed over to radosgw
    file { '/var/www/monitoring':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => Package['apache2'],
    }
    file { '/var/www/monitoring/frontend':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => "OK\n",
        require => File['/var/www/monitoring'],
    }
}
