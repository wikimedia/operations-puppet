# Class: profile::netbox::automation
#
# This profile creates and exposes git repositories created by automation.
#
# Actions:
#       Initialize git repositories
#       Create an apache site to expose these repositories.
#
# Requires:
#
# Sample Usage:
#       include profile::netbox::automation
#
class profile::netbox::automation (
    Stdlib::Fqdn $automation_service_hostname = lookup('profile::netbox::automation::git_hostname'),
    Array[Stdlib::Fqdn] $frontends = lookup('netbox_frontend', {'default_value' => []}),
    Boolean $has_acme = lookup('profile::netbox::acme', {'default_value' => true}),
    Stdlib::HTTPSUrl $nb_api = lookup('profile::netbox::netbox_api'),
    String $nb_ro_token = lookup('profile::netbox::tokens::read_only'),
    Integer $dns_min_records = lookup('profile::netbox::automation::dns_min_records'),
    Stdlib::Fqdn $active_server = lookup('profile::netbox::active_server'),
) {
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    # Create automation git repositories
    $repo_path = '/srv/netbox-exports'
    $repos = ['dns']

    $repos.each |String $repo| {
        netbox::autogit { $repo:
            repo_path => $repo_path,
            frontends => $frontends,
        }
    }

    # Expose automation git repositories
    # (this reuses the Netbox certificates).
    httpd::site { $automation_service_hostname:
        content => template('profile/netbox/netbox-exports.wikimedia.org.erb'),
        require => Acme_chief::Cert['netbox'],
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
        ensure => 'present',
        owner  => 'netbox',
        group  => 'netbox',
        mode   => '0644',
    }

    if $active_server == $::fqdn {
        $active_ensure = 'present'
    } else {
        $active_ensure = 'absent'
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
    }

}
