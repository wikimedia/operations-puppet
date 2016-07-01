class dnsrecursor::labsaliaser(
    $username,
    $password,
    $nova_api_url,
    $cnames,
    $alias_file,
    $admin_project_name,
) {

    require_package(['python-novaclient', 'python-keystoneclient'])

    $config = {
        'username'           => $username,
        'password'           => $password,
        'projects'           => $projects,
        'output_path'        => $alias_file,
        'nova_api_url'       => $nova_api_url,
        'cnames'             => $cnames,
        'admin_project_name' => $admin_project_name,
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

    exec { '/usr/local/bin/labs-ip-alias-dump.py':
        user    => 'root',
        group   => 'root',
        notify  => Service['pdns-recursor'],
        require => File[
            '/usr/local/bin/labs-ip-alias-dump.py',
            '/etc/labs-dns-alias.yaml'
        ],
        unless  => '/usr/local/bin/labs-ip-alias-dump.py --check-changes-only',
    }
}
