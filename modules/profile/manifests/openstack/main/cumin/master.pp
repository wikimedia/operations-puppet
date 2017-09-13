class profile::openstack::main::cumin::master(
    $openstack_protocol = hiera('profile::openstack::base::keystone::auth_protocol'),
    $openstack_host = hiera('labs_keystone_host'),
    $openstack_port = hiera('profile::openstack::base::keystone::public_port'),
    $openstack_project = hiera('profile::openstack::base::observer_project'),
    $openstack_username = hiera('profile::openstack::base::observer_user'),
    $openstack_password = hiera('profile::openstack::main::observer_password'),
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
