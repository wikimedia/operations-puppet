# == Class: profile::phabricator::monitoring
#
class profile::phabricator::monitoring (
    Stdlib::Fqdn $active_server = lookup('phabricator_server'),
    Stdlib::Ensure::Service $phd_service_ensure = lookup('profile::phabricator::main::phd_service_ensure', {'default_value' => 'running'}),
){

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
    if $::fqdn == $active_server {
        prometheus::blackbox::check::http { 'phabricator.wikimedia.org':
            severity => 'page',
        }
    }
}
