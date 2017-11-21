class profile::ganeti::monitoring {

    nrpe::monitor_service{ 'ganeti-noded':
        description  => 'ganeti-noded running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:2 -c 1:2 -u root -C ganeti-noded'
    }

    nrpe::monitor_service{ 'ganeti-confd':
        description  => 'ganeti-confd running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-confd -C ganeti-confd'
    }

    nrpe::monitor_service{ 'ganeti-mond':
        description  => 'ganeti-mond running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u root -C ganeti-mond'
    }

}
