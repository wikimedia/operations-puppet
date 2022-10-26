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
# [*profile::openstack::eqiad1::puppetdb_host*]
#   FQDN (the form used in Puppet certificates, so .wmflabs for older hosts)
#   of a project-local PuppetDB host, if any.
#
class profile::openstack::eqiad1::cumin::master(
    $keystone_protocol = lookup('profile::openstack::base::keystone::auth_protocol'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $keystone_port = lookup('profile::openstack::base::keystone::public_port'),
    $observer_username = lookup('profile::openstack::base::observer_user'),
    $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
    $nova_dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    Hash $aliases = lookup('profile::openstack::eqiad1::cumin::aliases'),
    $project_ssh_priv_key_path = lookup('profile::openstack::eqiad1::cumin::project_ssh_priv_key_path'),
    $region = lookup('profile::openstack::eqiad1::region'),
    Optional[Stdlib::Host] $puppetdb_host = lookup('profile::openstack::eqiad1::cumin::master::puppetdb_host', {default_value => undef}),
) {
        # TODO: simplify once hiera converts null properly to undef (this can be fixed now)
        if $::wmcs_project and $project_ssh_priv_key_path and $project_ssh_priv_key_path != '' and $project_ssh_priv_key_path != 'undef' {
            $is_project = true
            keyholder::agent { "cumin_openstack_${::wmcs_project}_master":
                trusted_groups => ['root'],
                priv_key_path  => $project_ssh_priv_key_path,
            }
        } else {
            $is_project = false
            keyholder::agent { 'cumin_openstack_master':
                trusted_groups => ['wmcs-roots', 'root'],
            }
        }

        # Explicitely require cumin's suggested packages to enable OpenStack backend,
        # --install-suggests would recursively install many more unwanted dependencies.
        # Install clustershell as it provides nodeset CLI that is useful to mangle host lists.
        package { ['clustershell', 'cumin']:
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

        if debian::codename::eq('buster') {
            apt::package_from_component { 'spicerack':
                component => 'component/spicerack',
                packages  => ['python3-tqdm'],
                priority  => 1002,
            }
        }

        $python_version = debian::codename() ? {
            'bullseye' => '3.9',
            'buster'   => '3.7',
            'stretch'  => '3.5',
            default    => fail("unsupported on ${debian::codename()}"),
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
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('labstore/nfs-mounts.yaml.erb'),
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
