# == Class: phabricator::monitoring
#
class phabricator::monitoring {

    include apache::mod::status
    diamond::collector { 'ApacheStatusSimple':
        source   => 'puppet:///modules/phabricator/monitor/apache_status.py',
    }

    nrpe::monitor_service { 'check_phab_taskmaster':
        description   => 'PHD should be supervising processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 3:150 -u phd',
        critical      => true,
    }

    monitoring::service { 'phabricator-https':
        description   => 'https://phabricator.wikimedia.org',
        check_command => 'check_https_phabricator',
        critical      => true,
    }
}
