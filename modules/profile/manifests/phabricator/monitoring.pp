# == Class: profile::phabricator::monitoring
#
class profile::phabricator::monitoring (
    $phabricator_active_server = hiera('phabricator_active_server')
){

    # Only monitor services on the active_server (at least until codfw is in prod).
    # They are all paging because the "sms" contact group is added.
    # https monitoring is on virtual host 'phabricator', should not be duplicated.
    if $::hostname == $phabricator_active_server {

        $phab_contact_groups = 'admins,phabricator'
        $phab_contact_groups_critical = 'admins,phabricator,sms'

        nrpe::monitor_service { 'check_phab_taskmaster':
            description   => 'PHD should be supervising processes',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 3:150 -u phd',
            contact_group => $phab_contact_groups,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Phabricator',
        }

        nrpe::monitor_service { 'check_phab_phd':
            description   => 'PHD should be running',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array  'php ./phd-daemon' -u phd",
            contact_group => $phab_contact_groups,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Phabricator',
        }

        monitoring::host { 'phabricator.wikimedia.org':
            host_fqdn => 'phabricator.wikimedia.org',
        }

        monitoring::service { 'phabricator-https':
            description   => 'https://phabricator.wikimedia.org',
            check_command => 'check_https_phabricator',
            contact_group => $phab_contact_groups_critical,
            host          => 'phabricator.wikimedia.org',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Phabricator',
        }
    }
}
