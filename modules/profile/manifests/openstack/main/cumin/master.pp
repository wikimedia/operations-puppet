# == profile::openstack::main::cumin::master
#
# Profile for setting up a Cumin master for WMCS.
# It allows to install Cumin master also inside a WMCS Cloud VPS project.
#
# === Hiera Parameters required for a project-specific Cumin master
#
# [*profile::openstack::main::cumin::project_ssh_priv_key_path*]
#   The absolute path of an SSH passphrase-protected private key available on
#   the host local filesystem.
#
# [*profile::openstack::main::cumin::aliases*]
#   Optional hash of Cumin aliases in the form:
#     key: 'alias query'
#
class profile::openstack::main::cumin::master(
    $keystone_protocol = hiera('profile::openstack::base::keystone::auth_protocol'),
    $keystone_host = hiera('profile::openstack::main::nova_controller'),
    $keystone_port = hiera('profile::openstack::base::keystone::public_port'),
    $observer_username = hiera('profile::openstack::base::observer_user'),
    $observer_password = hiera('profile::openstack::main::observer_password'),
    $nova_dhcp_domain = hiera('profile::openstack::main::nova::dhcp_domain'),
    $aliases = hiera('profile::openstack::main::cumin::aliases'),
    $project_ssh_priv_key_path = hiera('profile::openstack::main::cumin::project_ssh_priv_key_path'),
    ) {
        validate_hash($aliases)

        # TODO: simplify once hiera converts null properly to undef
        if $::labsproject and $project_ssh_priv_key_path and $project_ssh_priv_key_path != '' and $project_ssh_priv_key_path != 'undef' {
            $is_project = true
            ::keyholder::agent { "cumin_openstack_${::labsproject}_master":
                trusted_groups => ['root'],
                priv_key_path  => $project_ssh_priv_key_path,
            }
        } else {
            $is_project = false
            ::keyholder::agent { 'cumin_openstack_master':
                trusted_groups => ['wmcs-roots', 'root'],
            }
        }

        require_package([
            'cumin',
            'python-keystoneauth1',
            'python-keystoneclient',
            'python-novaclient',
        ])

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
            content => template('profile/openstack/main/cumin/ssh_config.erb'),
            require => File['/etc/cumin'],
        }
}
