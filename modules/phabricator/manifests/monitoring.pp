# == Class: phabricator::monitoring
#
class phabricator::monitoring {

    nrpe::monitor_service { 'check_phab_taskmaster':
        description  => 'check if phabricator taskmaster is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 10:30 -c 10:30 --ereg-argument-array PhabricatorTaskmasterDaemon',
        contact_group => 'admins,phabricator,sms',
    }

    monitoring::service { 'phabricator-https':
        description   => 'https://phabricator.wikimedia.org',
        check_command => 'check_https_phabricator',
        contact_group => 'admins,phabricator,sms',
    }

}
