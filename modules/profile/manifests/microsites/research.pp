# SPDX-License-Identifier: Apache-2.0
# https://research.wikimedia.org (T183916)
class profile::microsites::research(
  Stdlib::Fqdn $server_name = lookup('profile::microsites::research::server_name'),
  String $server_admin = lookup('profile::microsites::research::server_admin'),
) {

    httpd::site { 'research.wikimedia.org':
        content => template('profile/research/apache-research.wikimedia.org.erb'),
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/research')

    git::clone { 'research/landing-page':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/research',
        branch    => 'master',
    }

}

