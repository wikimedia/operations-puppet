# Most nova services don't access the Nova database directly; rather
#  they make rpc requests on rabbitmq.  The Conductor service handles
#  those those calls and passes them along to the database.
# http://blog.russellbryant.net/2012/11/19/a-new-nova-service-nova-conductor/

class openstack2::nova::conductor::service(
    $active,
    ) {

    require openstack2::nova::common

    package { 'nova-conductor':
        ensure  => present,
    }

    # Temp exclude
    #   subscribe => File['/etc/nova/nova.conf'],
    service { 'nova-conductor':
        ensure    => $active,
        require   => Package['nova-conductor'];
    }
}
