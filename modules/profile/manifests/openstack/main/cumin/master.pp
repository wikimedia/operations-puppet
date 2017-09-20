class profile::openstack::main::cumin::master(
    $keystone_protocol = hiera('profile::openstack::base::keystone::auth_protocol'),
    $keystone_host = hiera('profile::openstack::main::nova_controller'),
    $keystone_port = hiera('profile::openstack::base::keystone::public_port'),
    $observer_username = hiera('profile::openstack::base::observer_user'),
    $observer_password = hiera('profile::openstack::main::observer_password'),
    $nova_dhcp_domain = hiera('profile::openstack::main::nova::dhcp_domain'),
    ) {
        ::keyholder::agent { 'cumin_openstack_master':
            trusted_groups => ['wmcs-roots', 'root'],
        }

        require_package('cumin')

        # Variables used also in config.yaml
        $cumin_log_path = '/var/log/cumin'
        $ssh_config_path = '/etc/cumin/ssh_config'

        file { $cumin_log_path:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0750',
        }

        file { '/etc/cumin':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0750',
        }

        file { '/etc/cumin/config.yaml':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            content => template('profile/openstack/main/cumin/config.yaml.erb'),
            require => File['/etc/cumin'],
        }

        file { '/etc/cumin/aliases.yaml':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            content => template('profile/openstack/main/cumin/aliases.yaml.erb'),
            require => File['/etc/cumin'],
        }

        file { $ssh_config_path:
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            source  => 'puppet:///modules/profile/openstack/main/cumin/ssh_config',
            require => File['/etc/cumin'],
        }
}
