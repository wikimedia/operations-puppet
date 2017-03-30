class role::labs::dns_floating_ip_updater {
    $novaconfig = hiera_hash('novaconfig', {})
    $nova_controller_hostname = hiera('labs_nova_controller')
    $designateconfig = hiera_hash('designateconfig', {})

    $config = {
        'username'                                 => $novaconfig['observer_user'],
        'password'                                 => $novaconfig['observer_password'],
        'nova_api_url'                             => "http://${nova_controller_hostname}:35357/v3",
        'admin_project_name'                       => $novaconfig['observer_project'],
        'floating_ip_ptr_zone'                     => $designateconfig['floating_ip_ptr_zone'],
        'floating_ip_ptr_fqdn_matching_regex'      => $designateconfig['floating_ip_ptr_fqdn_matching_regex'],
        'floating_ip_ptr_fqdn_replacement_pattern' => $designateconfig['floating_ip_ptr_fqdn_replacement_pattern']
    }

    file { '/etc/labs-floating-ips-dns-config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    require_package('python-ipaddress')
    file { '/etc/dns-floating-ip-updater.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        source  => 'puppet:///modules/role/labs/dns-floating-ip-updater.py',
        require => Package['python-ipaddress']
    }

    cron { 'floating-ip-ptr-record-updater':
        minute  => '*/10',
        user    => 'root',
        command => '/etc/dns-floating-ip-updater.py >/dev/null 2>/dev/null',
    }
}
