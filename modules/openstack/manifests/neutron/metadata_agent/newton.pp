class openstack::neutron::metadata_agent::newton(
    $nova_controller,
    $metadata_proxy_shared_secret,
    $report_interval,
){
    class { "openstack::neutron::metadata_agent::newton::${::lsbdistcodename}": }

    file { '/etc/neutron/metadata_agent.ini':
        content => template('openstack/newton/neutron/metadata_agent.ini.erb'),
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        require => Package['neutron-metadata-agent'];
    }
}
