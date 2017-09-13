class profile::openstack::main::cumin(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $nova_api_host = hiera('profile::openstack::main::nova_api_host'),
    $keystone_auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $keystone_public_port = hiera('profile::openstack::base::keystone::public_port'),
    ) {
        ::keyholder::agent { 'cumin_openstack_master':
            trusted_groups => ['root'],
        }

        require_package('cumin')

        $cumin_log_path = '/var/log/cumin'  # Used also in config.yaml
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
}
