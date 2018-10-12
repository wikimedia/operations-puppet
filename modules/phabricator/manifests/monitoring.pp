# == Class: phabricator::monitoring
#
class phabricator::monitoring {

    diamond::collector { 'ApacheStatusSimple':
        ensure => 'absent',
        source => 'puppet:///modules/phabricator/monitor/apache_status.py',
    }

    $phabricator_active_server = hiera('phabricator_active_server')

    # Only monitor services on the active_server (at least until codfw is in prod).
    # They are all paging because the "sms" contact group is added.
    # https monitoring is on virtual host 'phabricator', should not be duplicated.
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

        monitoring::host { 'phabricator.wikimedia.org':
            host_fqdn => 'phabricator.wikimedia.org',
        }

        monitoring::service { 'phabricator-https':
            description   => 'https://phabricator.wikimedia.org',
            check_command => 'check_https_phabricator',
            contact_group => $phab_contact_groups,
            host          => 'phabricator.wikimedia.org',
        }
    }
}
