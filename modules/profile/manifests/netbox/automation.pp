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
    file { '/etc/netbox/dns.cfg':
        owner   => 'netbox',
        group   => 'netbox',
        mode    => '0440',
        content => template('profile/netbox/dns.cfg.erb'),
    }

    if $active_server == $::fqdn {
        $active_ensure = 'present'
    } else {
        $active_ensure = 'absent'
    }

    $nagios_command = '/srv/deployment/netbox-extras/dns/generate_dns_snippets.py commit --icinga-check "icinga-check"'
    sudo::user { 'nagios_uncommitted_dns_changes':
        ensure     => $active_ensure,
        user       => 'nagios',
        privileges => ["ALL = NOPASSWD: ${nagios_command}"],
    }

    nrpe::monitor_service { 'check_uncommitted_dns_changes':
        ensure         => $active_ensure,
        check_interval => 60,
        retry_interval => 15,
        description    => 'Uncommitted DNS changes in Netbox',
        nrpe_command   => "/usr/bin/sudo ${nagios_command}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Monitoring/Netbox_DNS_uncommitted_changes',
    }

}
