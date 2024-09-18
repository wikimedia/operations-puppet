# SPDX-License-Identifier: Apache-2.0
# @summary This profile creates and exposes git repositories created by automation.
#
# Actions:
#       Initialize git repositories
#       Create an apache site to expose these repositories.
#
# @example
#       include profile::netbox::automation
# @param git_hostname the hostname of the git endpoint
# @param dns_min_records the minimum number of dns records required
# @param frontends list of netbox frontends
class profile::netbox::automation (
    Stdlib::Fqdn        $git_hostname     = lookup('profile::netbox::automation::git_hostname'),
    Integer             $dns_min_records  = lookup('profile::netbox::automation::dns_min_records'),
    Array[Stdlib::Fqdn] $frontends        = lookup('profile::netbox::automation::frontend'),
) {
    include profile::netbox
    $ssl_paths     = $profile::netbox::ssl_paths
    $netbox_api    = $profile::netbox::netbox_api
    $ro_token      = $profile::netbox::ro_token
    $active_ensure = $profile::netbox::active_ensure

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    # Create automation git repositories
    $repo_path = '/srv/netbox-exports'
    $repos = ['dns']

    # TODO: migrate netbox::autogit to reposync
    $repos.each |String $repo| {
        netbox::autogit { $repo:
            repo_path => $repo_path,
            frontends => $frontends,
        }
    }
    class { 'reposync':
        target_only => true,
        group       => 'www-data',
        repos       => ['netbox-hiera'],
    }
    file { "${repo_path}/netbox-hiera":
        ensure => link,
        target => "${reposync::base_dir}/netbox-hiera",
    }

    # Expose automation git repositories
    # (this reuses the Netbox certificates).
    httpd::site { $git_hostname:
        content => template('profile/netbox/netbox-exports.wikimedia.org.erb'),
    }

    # Configuration for Netbox extras dns scripts
    $dns_repo_path = "${repo_path}/dns.git/"
    $icinga_state_file = '/var/run/netbox_generate_dns_snippets.state'
    file { '/etc/netbox/dns.cfg':
        owner   => 'netbox',
        group   => 'netbox',
        mode    => '0440',
        content => template('profile/netbox/dns.cfg.erb'),
    }

    file { $icinga_state_file:
        ensure => 'file',
        owner  => 'netbox',
        group  => 'netbox',
        mode   => '0644',
    }

    systemd::timer::job { 'check_netbox_uncommitted_dns_changes':
        ensure          => $active_ensure,
        description     => 'Run check for uncommitted DNS changes in Netbox and save state for NRPE',
        command         => '/srv/deployment/netbox-extras/dns/generate_dns_snippets.py commit --icinga-check "icinga-check"',
        interval        => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '5m',
        },
        logging_enabled => false,
        user            => 'netbox',
    }

    $check_command = '/usr/lib/nagios/plugins/check_json_file'
    $max_age = 4800  # 80 minutes
    file { $check_command:
        source => 'puppet:///modules/profile/netbox/check_json_file.py',
        mode   => '0755',
    }

    nrpe::monitor_service { 'check_uncommitted_dns_changes':
        ensure         => $active_ensure,
        check_interval => 5,
        retry_interval => 2,
        description    => 'Uncommitted DNS changes in Netbox',
        nrpe_command   => "${check_command} ${icinga_state_file} ${max_age}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/Netbox_DNS_uncommitted_changes',
        contact_group  => 'team-dcops',
    }

    prometheus::blackbox::check::http {
        'netbox-exports.wikimedia.org':  # Public endpoint (used by CI)
            path => '/dns.git/config';
        $facts['networking']['fqdn']:  # Internal endpoint (used by the dns script and cookbook)
            path => '/dns.git/config';
    }
}
