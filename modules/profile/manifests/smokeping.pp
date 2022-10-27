# http://oss.oetiker.ch/smokeping/
class profile::smokeping (
    Stdlib::Fqdn        $active_server   = lookup('netmon_server'),
    Array[Stdlib::Fqdn] $passive_servers = lookup('netmon_servers_failover'),
){

    class{ '::smokeping':
        ensure        => present,
        active_server => $active_server,
    }

    class{ '::smokeping::web':
        ensure => present,
    }

    ferm::service { 'smokeping-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'smokeping-https':
        proto => 'tcp',
        port  => '443',
    }

    backup::set { 'smokeping': }
}
