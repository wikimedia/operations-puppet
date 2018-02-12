# https://docs.openstack.org/liberty/install-guide-ubuntu/keystone-install.html
class openstack::keystone::bootstrap(
    $admin_token,
    $db_user,
    $db_pass,
    $region,
    ) {

    file {'/etc/keystone/bootstrap':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/etc/keystone/bootstrap/policy.json':
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0544',
        source  => 'puppet:///modules/openstack/bootstrap/keystone/policy.json',
        require => File['/etc/keystone/bootstrap'],
    }

    file { '/etc/keystone/bootstrap/admintoken':
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0544',
        content => template('modules/openstack/bootstrap/keystone/admintoken.erb'),
        require => File['/etc/keystone/bootstrap'],
    }

    file { '/etc/keystone/bootstrap/seed.sh':
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0544',
        content => template('modules/openstack/bootstrap/keystone/seed.sh.erb'),
        require => File['/etc/keystone/bootstrap'],
    }
}
