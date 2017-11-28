# Most nova services don't access the Nova database directly; rather
#  they make rpc requests on rabbitmq.  The Conductor service handles
#  those those calls and passes them along to the database.
# http://blog.russellbryant.net/2012/11/19/a-new-nova-service-nova-conductor/

class openstack::nova::conductor::service(
    $active,
    ) {

    require openstack::nova::common

    package { 'nova-conductor':
        ensure  => present,
    }

    service { 'nova-conductor':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-conductor'];
    }
}
