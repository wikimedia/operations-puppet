# == Class: profile::phabricator::monitoring
#
class profile::phabricator::monitoring (
    Stdlib::Fqdn $phabricator_active_server = hiera('phabricator_active_server'),
    Stdlib::Ensure::Service $phd_service_ensure = hiera('profile::phabricator::main::phd_service_ensure', 'running'),
){

    # All checks are paging because the "sms" contact group is added.
    # Only monitor PHD if it is actually set to be running in Hiera.
    if $phd_service_ensure == 'running' {

        $phab_contact_groups = 'admins,phabricator'

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
    }

    # https monitoring is on the virtual host 'phabricator'.
    # It should not be duplicated.
    if $::hostname == $phabricator_active_server {
        monitoring::host { 'phabricator.wikimedia.org':
            host_fqdn => 'phabricator.wikimedia.org',
        }

        monitoring::service { 'phabricator-https':
            description   => 'https://phabricator.wikimedia.org',
            check_command => 'check_https_phabricator',
            contact_group => $phab_contact_groups,
            critical      => true,
            host          => 'phabricator.wikimedia.org',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Phabricator',
        }
    }
}
