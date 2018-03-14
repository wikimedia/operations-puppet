class openstack::neutron::common(
    $version,
    $nova_controller,
    $db_pass,
    $db_user,
    $db_host,
    $region,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_pass,
    ) {

    package{ 'neutron-common':
        ensure => 'present',
    }

    file { '/etc/neutron/neutron.conf':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0660',
            content => template("openstack/${version}/neutron/neutron.conf.erb"),
            require => Package['neutron-common'];
    }

    file { '/etc/neutron/policy.json':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/mitaka/neutron/policy.json',
            require => Package['neutron-common'];
    }


    if os_version('debian == jessie') {

        file {'/etc/neutron/original':
            ensure  => 'directory',
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0755',
            recurse => true,
            source  => "puppet:///modules/openstack/${version}/neutron/original",
        }
    }
}
