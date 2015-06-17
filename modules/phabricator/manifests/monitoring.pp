# == Class: phabricator::monitoring
#
class phabricator::monitoring {

    nrpe::monitor_service { 'check_phab_taskmaster':
        description   => 'PHD should be supervising processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 3:150 -u phd'
        contact_group => 'admins,phabricator,sms',
    }

    monitoring::service { 'phabricator-https':
        description   => 'https://phabricator.wikimedia.org',
        check_command => 'check_https_phabricator',
        contact_group => 'admins,phabricator,sms',
    }

}
