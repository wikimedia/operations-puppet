# == Class: role::ve
#
# Sets up a Visual Editor performance testing rig with a headless
# Chromium instance that supports remote debugging.
#
class role::ve {
    include ::role::jsbench
    include ::mediawiki
    include ::mediawiki::web
    include ::mediawiki::web::sites
    include ::mediawiki::web::prod_sites

    file { '/usr/local/bin/vb':
        source => 'puppet:///modules/role/ve/vb',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    apache::site { 'devwiki':
        source   => 'puppet:///modules/role/ve/devwiki.conf',
        priority => 4,
    }
}
