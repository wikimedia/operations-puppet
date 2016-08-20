class role::toollabs::clush::master {
    class { '::clush::master':
        username => 'clushuser',
    }

    require_package('python3-yaml')

    file { '/usr/local/sbin/tools-clush-generator':
        ensure => file,
        source => 'puppet:///modules/role/toollabs/clush/tools-clush-generator',
        owner  => 'root'
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/tools-clush-interpreter':
        ensure => file,
        source => 'puppet:///modules/role/toollabs/clush/tools-clush-interpreter',
        owner  => 'root',
        grou   => 'root',
        mode   => '0555',
    }

    cron { 'update_tools_clush':
        ensure  => present,
        command => '/usr/local/sbin/tools-clush-generator /etc/clustershell/tools.yaml',
        hour    => '*/1',
        user    => 'root'
    }
}
