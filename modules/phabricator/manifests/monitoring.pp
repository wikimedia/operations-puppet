# == Class: phabricator::monitoring
#
class phabricator::monitoring {

    diamond::collector { 'ApacheStatusSimple':
        source   => 'puppet:///modules/phabricator/monitor/apache_status.py',
    }

    $phabricator_active_server = hiera('phabricator_active_server')

    # (only if) on active server monitor that PHD is running,
    # and send actual SMS to contacts. monitor https on all though.
    if $::hostname == $phabricator_active_server {
        $phab_contact_groups = 'admins,phabricator,sms'

        nrpe::monitor_service { 'check_phab_taskmaster':
            description   => 'PHD should be supervising processes',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 3:150 -u phd',
            contact_group => $phab_contact_groups,
        }

        nrpe::monitor_service { 'check_phab_phd':
            description   => 'PHD should be running',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array  'php ./phd-daemon' -u phd",
            contact_group => $phab_contact_groups,
        }
    } else {
        $phab_contact_groups = 'admins,phabricator'
    }

    monitoring::service { 'phabricator-https':
        description   => 'https://phabricator.wikimedia.org',
        check_command => 'check_https_phabricator',
        contact_group => $phab_contact_groups,
    }

}
