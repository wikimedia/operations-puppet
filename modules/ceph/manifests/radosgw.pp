class ceph::radosgw(
    $servername='localhost',
    $serveradmin='webmaster@localhost',
) {
    Class['ceph::radosgw'] -> Class['ceph']

    package { [ 'radosgw', 'radosgw-dbg' ]:
        ensure => present,
    }

    service { 'radosgw id=radosgw':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        provider   => 'upstart',
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
}
