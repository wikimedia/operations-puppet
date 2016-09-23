# == Class: role::pivot
class role::pivot {

    system::role { 'role::pivot':
        description => "Imply Pivot UI"
    }

    class { '::pivot':
        port          => 9090,
        druid_broker  => 'druid1001.eqiad.wmnet:8082',
        contact_group => 'analytics',
    }

    ferm::service { 'pivot':
        proto => 'tcp',
        port  => '9090',
    }
}