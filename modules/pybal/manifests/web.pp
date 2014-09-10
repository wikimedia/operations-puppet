class pybal::web ($ensure = 'present', $hostname == 'pybal-config.wikimedia.org') {

    include wmflib

    $is_24 = ubuntu_version('>= trusty')

    apache::site { 'pybal-config':
        ensure => $ensure,
        priority => 50,
        content  => template('pybal/config-vhost.conf.erb'),
        notify   => Service['apache2'],
        require  => File['/srv/pybal-config']
    }

    file { '/srv/pybal-config':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

}
