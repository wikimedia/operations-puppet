class ceph::radosgw(
    $servername='localhost',
    $serveradmin='webmaster@localhost',
) {
    Class['ceph'] -> Class['ceph::radosgw']

    package { [ 'radosgw', 'radosgw-dbg' ]:
        ensure => present,
    }

    service { 'radosgw id=radosgw':
        ensure     => 'running',
        hasrestart => true,
        # upstart status is broken with id= ...
        status     => '/usr/bin/pgrep radosgw',
        provider   => 'upstart',
        require    => Package['radosgw'],
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
    }

    class { 'apache':
        default_mods => false,
        serveradmin  => $serveradmin,
    }
    apache::mod { 'fastcgi':
        package => 'libapache2-mod-fastcgi',
    }
    apache::mod { 'rewrite': }

    file { '/etc/apache2/sites-available/radosgw':
        ensure  => present,
        content => template('ceph/radosgw/vhost.erb'),
        require => [
            Package['apache2'],
            Apache::Mod['fastcgi'],
            Apache::Mod['rewrite'],
            ],
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

    file { '/var/www/monitoring':
        ensure  => directory,
        require => Package['apache2'],
    }
    file { '/var/www/monitoring/frontend':
        ensure  => present,
        content => "OK\n",
        require => File['/var/www/monitoring'],
    }
}
