# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api($novaconfig, $openstack_version=$::openstack::version) {
    include ::openstack::repo

    package { 'nova-api':
        ensure  => present,
        require => Class['openstack::repo'];
    }

    service { 'nova-api':
        ensure    => running,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-api'];
    }
    file { '/etc/nova/policy.json':
        source  => "puppet:///modules/openstack/${openstack_version}/nova/policy.json",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        notify  => Service['nova-api'],
        require => Package['nova-api'];
    }

    nrpe::monitor_service { 'check_nova_api_process':
        description  => 'nova-api process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-api'",
    }
    monitoring::service { 'nova-api-http':
        description   => 'nova-api http',
        check_command => 'check_http_on_port!8774',
    }
}
