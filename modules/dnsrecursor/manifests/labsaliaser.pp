class dnsrecursor::labsaliaser(
    $username,
    $password,
    $projects,
    $alias_file,
) {

    require_package('python-novaclient')

    $config = {
        'username'    => $username,
        'password'    => $password,
        'projects'    => $projects,
        'output_path' => $alias_file,
    }

    file { '/etc/labs-dns-alias.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => ordered_yaml($config),
    }

    file { '/usr/local/bin/labs-ip-alias-dump.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/dnsrecursor/labs-ip-alias-dump.py',
    }

    exec { '/usr/local/bin/labs-ip-alias-dump.py':
        user    => 'root',
        group   => 'root',
        notify  => Service['pdns-recursor'],
        require => File[
            '/usr/local/bin/labs-ip-alias-dump.py',
            '/etc/labs-dns-alias.yaml'
        ],
        ifonly => '/usr/local/bin/labs-ip-alias-dump.py --check-changes-only',
    }
}
