# == Class: phabricator::monitoring
#
class phabricator::monitoring {

    include ::apache::mod::status
    diamond::collector { 'ApacheStatusSimple':
        source   => 'puppet:///modules/phabricator/monitor/apache_status.py',
    }

    $phabricator_active_server = hiera('phabricator_active_server')

    if $::hostname == $phabricator_active_server {
        $phab_contact_groups = 'admins,phabricator,sms'
    } else {
        $phab_contact_groups = 'admins,phabricator'
    }

    nrpe::monitor_service { 'check_phab_taskmaster':
        description   => 'PHD should be supervising processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 3:150 -u phd',
        contact_group => $phab_contact_groups,
    }

    monitoring::service { 'phabricator-https':
        description   => 'https://phabricator.wikimedia.org',
        check_command => 'check_https_phabricator',
        contact_group => $phab_contact_groups,
    }

}
