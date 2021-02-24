class profile::cumin::unprivmaster (
    Stdlib::Host  $puppetdb_host        = lookup('puppetdb_host'),
    Array[String] $datacenters          = lookup('datacenters'),
    Stdlib::Host  $kerberos_kadmin_host = lookup('kerberos_kadmin_server_primary')
) {
    include profile::kerberos::client

    $cumin_log_path = '/var/log/cumin'
    $ssh_config_path = '/etc/cumin/ssh_config'

    ensure_packages([
        'clustershell',  # Installs nodeset CLI that is useful to mangle host lists.
        'cumin',
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
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/cumin/config-unpriv.yaml.erb'),
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
