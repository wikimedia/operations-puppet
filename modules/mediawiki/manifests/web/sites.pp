class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'

    file { '/etc/apache2/sites-enabled/wikimedia-legacy.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikimedia-legacy.incl',
        before => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/public-wiki-rewrites.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/public-wiki-rewrites.incl',
        before => Service['apache2'],
    }

    file { '/etc/apache2/sites-enabled/api-rewrites.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/api-rewrites.incl',
        before => Service['apache2'],
    }

    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }
}
