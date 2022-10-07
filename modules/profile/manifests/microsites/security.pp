# SPDX-License-Identifier: Apache-2.0
# https://security.wikimedia.org (T257834)
class profile::microsites::security(
  $server_name = lookup('profile::microsites::security::server_name'),
  $server_admin = lookup('profile::microsites::security::server_admin'),
) {

    httpd::site { 'security.wikimedia.org':
        content => template('profile/security/security.wikimedia.org.erb'),
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/security')

    git::clone { 'wikimedia/security/landing-page':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/security',
        branch    => 'master',
    }

}

