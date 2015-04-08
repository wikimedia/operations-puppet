# == Class: role::statsdlb
#
# Provisions a statsdlb instance that listens for StatsD metrics on
# on UDP port 8125 and forwards to backends on UDP ports 8126-8128,
# as well as the set of statsite backends that listen on these ports.
#
class role::statsdlb {

    # statsdlb

    class { '::statsdlb':
        server_port   => 8125,
        backend_ports => range(8126, 8128),
    }

    nrpe::monitor_service { 'statsdlb':
        description  => 'statsdlb process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C statsdlb',
    }

    class { '::txstatsd::decommission': }
    class { '::statsite': }

    # statsite backends
    statsite::instance { '8126':
        port          => 8126,
        input_counter => "statsd.${::hostname}-8126.received",
    }

    statsite::instance { '8127':
        port          => 8127,
        input_counter => "statsd.${::hostname}-8127.received",
    }

    statsite::instance { '8128':
        port          => 8128,
        input_counter => "statsd.${::hostname}-8128.received",
    }

    nrpe::monitor_service { 'statsite_backends':
        description  => 'statsite backend instances',
        nrpe_command => '/sbin/statsitectl check',
        require      => Service['statsite'],
    }

    diamond::collector { 'UDPCollector': }
}
