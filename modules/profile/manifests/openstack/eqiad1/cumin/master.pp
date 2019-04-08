# == profile::openstack::eqiad1::cumin::master
#
# Profile for setting up a Cumin master for WMCS.
# It allows to install Cumin master also inside a WMCS Cloud VPS project.
#
# === Hiera Parameters required for a project-specific Cumin master
#
# [*profile::openstack::eqiad1::cumin::project_ssh_priv_key_path*]
#   The absolute path of an SSH passphrase-protected private key available on
#   the host local filesystem.
#
# [*profile::openstack::eqiad1::cumin::aliases*]
#   Optional hash of Cumin aliases in the form:
#     key: 'alias query'
#
class profile::openstack::eqiad1::cumin::master(
    $keystone_protocol = hiera('profile::openstack::base::keystone::auth_protocol'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $keystone_port = hiera('profile::openstack::base::keystone::public_port'),
    $observer_username = hiera('profile::openstack::base::observer_user'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
    $nova_dhcp_domain = hiera('profile::openstack::eqiad1::nova::dhcp_domain'),
    $aliases = hiera('profile::openstack::eqiad1::cumin::aliases'),
    $project_ssh_priv_key_path = hiera('profile::openstack::eqiad1::cumin::project_ssh_priv_key_path'),
    $region = hiera('profile::openstack::eqiad1::region'),
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

        # Explicitely require cumin's suggested packages to enable OpenStack backend,
        # --install-suggests would recursively install many more unwanted dependencies.
        # Install clustershell as it provides nodeset CLI that is useful to mangle host lists.
        package { ['clustershell', 'cumin', 'python3-keystoneauth1', 'python3-keystoneclient', 'python3-novaclient']:
            ensure => present,
        }

        # Variables used also in config.yaml
        $cumin_log_path = '/var/log/cumin'
        $ssh_config_path = '/etc/cumin/ssh_config'

        file { $cumin_log_path:
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0750',
            require => Package['cumin'],
        }

        file { '/etc/cumin':
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0750',
            require => Package['cumin'],
        }

        file { '/etc/cumin/config.yaml':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            content => template('profile/openstack/eqiad1/cumin/config.yaml.erb'),
            require => File['/etc/cumin'],
        }

        file { '/etc/cumin/aliases.yaml':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            content => template('profile/openstack/eqiad1/cumin/aliases.yaml.erb'),
            require => File['/etc/cumin'],
        }

        file { $ssh_config_path:
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            content => template('profile/openstack/eqiad1/cumin/ssh_config.erb'),
            require => File['/etc/cumin'],
        }

        if os_version('debian == jessie') {
            $python_version = '3.4'
        } elsif os_version('debian == stretch') {
            $python_version = '3.5'
        } else {
            $python_version = '3.6'
        }

        file { "/usr/local/lib/python${python_version}/dist-packages/cumin_file_backend.py":
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            source  => 'puppet:///modules/profile/openstack/eqiad1/cumin/cumin_file_backend.py',
            require => File['/etc/cumin'],
        }

        file { '/etc/nfs-mounts.yaml':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/labstore/nfs-mounts.yaml',
        }

        file { '/usr/local/sbin/nfs-hostlist':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0550',
            source  => 'puppet:///modules/profile/openstack/eqiad1/cumin/nfs_hostlist.py',
            require => [
                File['/etc/nfs-mounts.yaml'],
                File['/etc/cumin'],
            ],
        }
}
