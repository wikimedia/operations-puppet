# Most nova services don't access the Nova database directly; rather
#  they make rpc requests on rabbitmq.  The Conductor service handles
#  those those calls and passes them along to the database.
# http://blog.russellbryant.net/2012/11/19/a-new-nova-service-nova-conductor/

class openstack::nova::conductor {
    include openstack::repo

    package { 'nova-conductor':
        ensure  => present,
        require => Class['openstack::repo'];
    }

    if $::fqdn == hiera('labs_nova_controller') {
        service { 'nova-conductor':
            ensure    => running,
            subscribe => File['/etc/nova/nova.conf'],
            require   => Package['nova-conductor'];
        }

        nrpe::monitor_service { 'check_nova_conductor_process':
            description  => 'nova-conductor process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-conductor'",
            critical     => true,
        }
    } else {
        service { 'nova-conductor':
            ensure    => stopped,
            require   => Package['nova-conductor'];
        }
    }
}
