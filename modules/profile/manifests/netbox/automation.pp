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
    Stdlib::Fqdn $automation_service_hostname = lookup('profile::netbox::automation_git_hostname'),
    Array[Stdlib::Fqdn] $frontends = lookup('netbox_frontend', {'default_value' => []}),
    Boolean $has_acme = lookup('profile::netbox::acme', {'default_value' => true}),

) {
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    # Create automation git repositories
    $repo_path = '/srv/automation'
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
}
