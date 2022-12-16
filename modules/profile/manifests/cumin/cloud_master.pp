# SPDX-License-Identifier: Apache-2.0
# @summary profile to manage cloud_cumin masters
# @param puppetdb_host the host running puppetdb
# @param datacenters list of datacenters
# @param kerberos_kadmin_host the host running kerberos kadmin
class profile::cumin::cloud_master (
    Stdlib::Host  $puppetdb_host           = lookup('puppetdb_host'),
    Array[String] $datacenters             = lookup('datacenters'),
    Stdlib::Host  $kerberos_kadmin_host    = lookup('kerberos_kadmin_server_primary'),
    Stdlib::Port  $puppetdb_port           = lookup('profile::puppetdb::microservice::port'),
) {
    include passwords::phabricator
    $cumin_log_path = '/var/log/cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'
    # Ensure to add FQDN of the current host also the first time the role is applied
    $cumin_masters = (wmflib::role::hosts('cluster::cloud_management') << $facts['networking']['fqdn']).sort.unique
    $mariadb_roles = Profile::Mariadb::Role
    $mariadb_sections = Profile::Mariadb::Valid_section
    $owners = profile::contacts::get_owners().values.flatten.unique

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
