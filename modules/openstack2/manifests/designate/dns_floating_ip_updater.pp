class openstack2::designate::dns_floating_ip_updater(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $observer_user = hiera('profile::openstack::base::observer_user')
    $observer_pass = hiera('profile::openstack::main::observer_password'),
    $observer_project = hiera('profile::openstack::base::observer_project'),
    $floating_ip_ptr_zone = hiera('profile::openstack::main::designate::floating_ip_ptr_zone'),
    $floating_ip_ptr_fqdn_matching_regex = hiera('profile::openstack::main::designate::floating_ip_ptr_fqdn_matching_regex'),
    $floating_ip_ptr_fqdn_replacement_pattern = hiera('profile::openstack::main::designate::floating_ip_ptr_fqdn_replacement_pattern'),
    ) {

    require_package('python-ipaddress')

    $config = {
        'username'                                 => $observer_user,
        'password'                                 => $observer_pass,
        'nova_api_url'                             => "http://${nova_controller}:35357/v3",
        'admin_project_name'                       => $observer_project,
        'floating_ip_ptr_zone'                     => $floating_ip_ptr_zone,
        'floating_ip_ptr_fqdn_matching_regex'      => $floating_ip_ptr_fqdn_matching_regex,
        'floating_ip_ptr_fqdn_replacement_pattern' => $floating_ip_ptr_fqdn_replacement_pattern,
    }

    file { '/etc/labs-floating-ips-dns-config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    file { '/etc/dns-floating-ip-updater.py':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        source  => 'puppet:///modules/openstack2/designate/dns-floating-ip-updater.py',
        require => Package['python-ipaddress']
    }

    cron { 'floating-ip-ptr-record-updater':
        minute  => '*/10',
        user    => 'root',
        command => '/etc/dns-floating-ip-updater.py >/dev/null 2>/dev/null',
    }
}
