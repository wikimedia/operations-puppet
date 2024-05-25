# SPDX-License-Identifier: Apache-2.0
class profile::cumin::unprivmaster (
    Array[String] $datacenters           = lookup('datacenters'),
    Stdlib::Host  $kerberos_kadmin_host  = lookup('kerberos_kadmin_server_primary'),
    Stdlib::Port  $puppetdb_micro_port   = lookup('profile::puppetdb::microservice::port'),
    Integer       $cumin_connect_timeout = lookup('profile::cumin::master::connect_timeout', {'default_value' => 10}),
    Stdlib::Host  $puppetdb_micro_host   = lookup('profile::cumin::unprivmaster::puppetdb_micro_host'),
) {
    include profile::kerberos::client

    # These are referenced by the aliases template, but otherwise unused
    $mariadb_roles = Profile::Mariadb::Role
    $mariadb_sections = Profile::Mariadb::Valid_section


    $cumin_log_path = '~/.cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'
    $owners = profile::contacts::get_owners().values.flatten.unique
    $lvs_hosts = wmflib::service::get_lvs_class_hosts()

    ensure_packages([
        'clustershell',  # Installs nodeset CLI that is useful to mangle host lists.
        'cumin',
    ])

    file { '/etc/cumin':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/cumin/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/cumin/config-unpriv.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { '/etc/cumin/aliases.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/cumin/aliases.yaml.erb'),
        require => File['/etc/cumin'],
    }

    file { $ssh_config_path:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/cumin/ssh_config-unpriv',
    }
}
