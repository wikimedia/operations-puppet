class role::labs::dns_floating_ip_updater {
    $keystoneconfig = hiera_hash('keystoneconfig', {})
    $wikitech_nova_ldap_user_pass = $keystoneconfig['ldap_user_pass']
    $wikitech_nova_admin_project_name = $keystoneconfig['admin_project_name']
    $nova_controller_hostname = hiera('labs_nova_controller')

    $config = {
        'username'           => 'novaadmin',
        'password'           => $wikitech_nova_ldap_user_pass,
        'nova_api_url'       => "http://${nova_controller_hostname}:35357/v2.0",
        'admin_project_name' => $wikitech_nova_admin_project_name,
    }

    file { '/etc/labs-floating-ips-dns-config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    file { '/etc/dns-floating-ip-updater.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
        source => 'puppet:///modules/role/labs/dns-floating-ip-updater.py'
    }

    cron { 'floating-ip-ptr-record-updater':
        minute  => '*/10',
        user    => 'root',
        command => '/etc/dns-floating-ip-updater.py',
    }
}
