# SPDX-License-Identifier: Apache-2.0
# Provisions the Wikimedia Transparency Report static site
# hosted at <http://transparency.wikimedia.org>.
#
class profile::microsites::transparency {

    $repo_dir = '/srv/org/wikimedia/TransparencyReport'
    $docroot  = "${repo_dir}/build"

    git::clone { 'wikimedia/TransparencyReport':
        ensure    => present,
        directory => $repo_dir,
    }

    httpd::site { 'transparency.wikimedia.org':
        content => template('role/apache/sites/transparency.wikimedia.org.erb'),
    }

    httpd::site { 'transparency-archive.wikimedia.org':
        content => template('role/apache/sites/transparency-archive.wikimedia.org.erb'),
    }
}
