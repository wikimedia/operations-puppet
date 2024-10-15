# SPDX-License-Identifier: Apache-2.0
# @summary profile to install the requestctl web interface
#
# @param api_tokens Hash[str, str] a dictionary of username-token pairs
class profile::conftool::hiddenparma (
    Hash[String, String] $api_tokens = lookup('profile::conftool::hiddenparma::api_tokens'),
) {
    require profile::conftool::client
    # Create the /srv/deployment directory if it doesn't exist
    if (!defined(File['/srv/deployment'])) {
        file { '/srv/deployment':
            ensure => directory,
        }
    }

    $user = 'deploy-hiddenparma'
    file { '/etc/default/hiddenparma':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/conftool/hiddenparma-default.erb'),
    }

    fastapi::application { 'hiddenparma':
        port   => 8080,
    }

    file { '/etc/HIDDENPARMA':
        ensure  => directory,
        owner   => $user,
        group   => $user,
        mode    => '0550',
        require => Fastapi::Application['hiddenparma'],
    }

    file { '/etc/HIDDENPARMA/api_tokens.json':
        ensure  => file,
        owner   => $user,
        group   => $user,
        mode    => '0440',
        content => to_json($api_tokens),
    }
    # Apache and CAS auth setup
    profile::idp::client::httpd::site { 'requestctl.wikimedia.org':
        require         => [
            Acme_chief::Cert['icinga'],
        ],
        vhost_content   => 'profile/conftool/httpd-hiddenparma.conf.erb',
        # Only full roots can access this.
        required_groups => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
        ],
        vhost_settings  => { proxy_pass => 'http://localhost:8080/' },
    }
}
