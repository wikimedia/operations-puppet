# SPDX-License-Identifier: Apache-2.0
# Provisions static site as graveyard of tendril
# hosted at <http://tendril.wikimedia.org> and <http://dbtree.wikimedia.org>.
#
class profile::microsites::static_tendril {

    $docroot = '/srv/org/wikimedia/static-tendril'

    wmflib::dir::mkdir_p($docroot)

    file { "${docroot}/index.html":
        source => 'puppet:///modules/profile/microsites/static-tendril-index.html',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
    }


    # tendril.wikimedia.org and dbtree.wikimedia.org as alias
    httpd::site { 'static-tendril.wikimedia.org':
        content => template('profile/microsites/static-tendril.wikimedia.org.erb'),
    }
}
