# SPDX-License-Identifier: Apache-2.0
# @summary profile to manage cloud_cumin masters
# @param datacenters list of datacenters
# @param kerberos_kadmin_host the host running kerberos kadmin
# @param puppetdb_micro_host the host running puppetdb-api micro service
# @param puppetdb_micro_port the port running puppetdb-api micro service
class profile::cumin::cloud_master (
    Array[String] $datacenters           = lookup('datacenters'),
    Stdlib::Host  $kerberos_kadmin_host  = lookup('kerberos_kadmin_server_primary'),
    String        $keystone_protocol     = lookup('profile::openstack::base::keystone::auth_protocol'),
    Stdlib::Host  $keystone_api_fqdn     = lookup('profile::cumin::cloud_master::keystone_api_fqdn'),
    Stdlib::Port  $keystone_port         = lookup('profile::openstack::base::keystone::public_port'),
    String        $observer_username     = lookup('profile::openstack::base::observer_user'),
    String        $observer_password     = lookup('profile::openstack::main::observer_password'),
    Stdlib::Host  $nova_dhcp_domain      = lookup('profile::cumin::cloud_master::nova_dhcp_domain'),
    String        $openstack_region      = lookup('profile::cumin::cloud_master::openstack_region'),
    Stdlib::Host  $puppetdb_micro_host   = lookup('profile::cumin::cloud_master::puppetdb_micro_host'),
    Stdlib::Port  $puppetdb_micro_port   = lookup('profile::cumin::cloud_master::puppetdb_micro_port'),
    Integer       $cumin_connect_timeout = lookup('profile::cumin::master::connect_timeout', {'default_value' => 10}),
) {
    include passwords::phabricator
    $with_openstack = true  # Used in the cumin/config.yaml.erb template
    $cumin_log_path = '/var/log/cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'
    # Ensure to add FQDN of the current host also the first time the role is applied
    $cumin_masters = (wmflib::role::hosts('cluster::cloud_management') << $facts['networking']['fqdn']).sort.unique
    $mariadb_roles = Profile::Mariadb::Role
    $mariadb_sections = Profile::Mariadb::Valid_section
    $owners = profile::contacts::get_owners().values.flatten.unique
    $lvs_hosts = wmflib::service::get_lvs_class_hosts()

    keyholder::agent { 'cloud_cumin_master':
        trusted_groups => ['root'],
    }

    keyholder::agent { 'cumin_openstack_master':
        trusted_groups => ['root'],
    }

    ensure_packages([
        'clustershell',  # Installs nodeset CLI that is useful to mangle host lists.
        'cumin',
        'python3-dnspython',
        'python3-phabricator',
        'python3-requests',
        # Explicitely require cumin's suggested packages to enable OpenStack backend, bacause
        # --install-suggests would recursively install many more unwanted dependencies.
        'python3-keystoneauth1',
        'python3-keystoneclient',
        'python3-novaclient',
    ])

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
        mode   => '0755',
    }

    file { '/etc/cumin/config.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config.yaml.erb'),
    }

    file { '/etc/cumin/config-installer.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/config-installer.yaml.erb'),
    }

    file { '/etc/cumin/aliases.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/cumin/aliases.yaml.erb'),
    }

    file { $ssh_config_path:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/cumin/cloud_ssh_config.erb'),
    }

    class { 'phabricator::bot':
        username => 'ops-monitoring-bot',
        token    => $passwords::phabricator::ops_monitoring_bot_token,
        owner    => 'root',
        group    => 'root',
    }
}
