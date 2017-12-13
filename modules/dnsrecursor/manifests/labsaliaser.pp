class dnsrecursor::labsaliaser(
    $username,
    $password,
    $nova_api_url,
    $extra_records,
    $alias_file,
    $observer_project_name,
) {

    $config = {
        'username'              => $username,
        'password'              => $password,
        'output_path'           => $alias_file,
        'nova_api_url'          => $nova_api_url,
        'extra_records'         => $extra_records,
        'observer_project_name' => $observer_project_name,
    }

    file { '/etc/labs-dns-alias.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    file { '/usr/local/bin/labs-ip-alias-dump.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/dnsrecursor/labs-ip-alias-dump.py',
    }

    cron { 'labs-ip-alias-dump':
        ensure  => 'present',
        user    => 'root',
        command => '/usr/local/bin/labs-ip-alias-dump.py --check-changes-only || /usr/local/bin/labs-ip-alias-dump.py',
        minute  => 30,
        notify  => Service['pdns-recursor'],
        require => File[
            '/usr/local/bin/labs-ip-alias-dump.py',
            '/etc/labs-dns-alias.yaml'
        ],
    }
}
