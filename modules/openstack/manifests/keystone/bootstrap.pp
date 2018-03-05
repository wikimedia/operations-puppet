# https://docs.openstack.org/liberty/install-guide-ubuntu/keystone-install.html
class openstack::keystone::bootstrap(
    $region,
    $db_user,
    $db_pass,
    $admin_token,
    ) {

    file {'/etc/keystone/bootstrap':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/etc/keystone/bootstrap/admintoken':
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0544',
        content => template('openstack/bootstrap/keystone/admintoken.erb'),
        require => File['/etc/keystone/bootstrap'],
    }

    file { '/etc/keystone/bootstrap/seed.sh':
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0544',
        content => template('openstack/bootstrap/keystone/keystone_seed.sh.erb'),
        require => File['/etc/keystone/bootstrap'],
    }

    file { '/etc/keystone/bootstrap/keystone.conf.bootstrap':
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0544',
        content => template('openstack/bootstrap/keystone/keystone.conf.bootstrap.erb'),
        require => File['/etc/keystone/bootstrap'],
    }
}
