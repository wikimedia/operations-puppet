class openstack::designate::dns_floating_ip_updater(
    $floating_ip_ptr_zone,
    $floating_ip_ptr_fqdn_matching_regex,
    $floating_ip_ptr_fqdn_replacement_pattern,
    ) {

    # also requires openstack::clientlib
    require_package('python-ipaddress')

    $config = {
        'floating_ip_ptr_zone'                     => $floating_ip_ptr_zone,
        'floating_ip_ptr_fqdn_matching_regex'      => $floating_ip_ptr_fqdn_matching_regex,
        'floating_ip_ptr_fqdn_replacement_pattern' => $floating_ip_ptr_fqdn_replacement_pattern,
    }

    file { '/etc/labs-floating-ips-dns-config.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    file { '/etc/dns-floating-ip-updater.py':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        source  => 'puppet:///modules/openstack/designate/dns-floating-ip-updater.py',
        require => Package['python-ipaddress']
    }

    cron { 'floating-ip-ptr-record-updater':
        minute  => '*/10',
        user    => 'root',
        command => '/etc/dns-floating-ip-updater.py >/dev/null 2>/dev/null',
        require => File['/etc/dns-floating-ip-updater.py'],
    }
}
