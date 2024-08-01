# SPDX-License-Identifier: Apache-2.0
# == Class: profile::phabricator::monitoring
#
class profile::phabricator::monitoring (
    Stdlib::Fqdn $active_server = lookup('phabricator_active_server'),
){

    $phab_contact_groups = 'admins,phabricator'

    # https monitoring is on the virtual host 'phabricator'.
    # It should not be duplicated.
    if $::fqdn == $active_server {
        prometheus::blackbox::check::http { 'phabricator.wikimedia.org':
            severity    => 'page',
            alert_after => '30m',
            timeout     => '6s',
        }

        # dedicated check with collab team and severity task
        # Reporting to a phab task might not work if phabricator is down
        prometheus::blackbox::check::http { 'phabricator.wikimedia.org-collab':
            server_name        => 'phabricator.wikimedia.org',
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/',
            force_tls          => true,
            port               => 443,
            ip_families        => [ip4],
            timeout            => '6s',
            body_regex_matches => ['Welcome to Wikimedia Phabricator'],
        }

        nrpe::monitor_service { 'check_phab_phd':
            description   => 'PHD should be running',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array  'php ./phd-daemon' -u phd",
            contact_group => $phab_contact_groups,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Phabricator',
        }
    }

    prometheus::blackbox::check::tcp { 'phabricator-smtp':
        team     => 'collaboration-services',
        severity => 'task',
        port     => 25,
    }

}
