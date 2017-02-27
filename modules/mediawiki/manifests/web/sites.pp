class mediawiki::web::sites (
    $domain_suffix = 'org',
    $portal_dir = 'portal'
) {
    tag 'mediawiki', 'mw-apache-config'

    #common code snippets that are included in the virtualhosts.
    file { '/etc/apache2/sites-enabled/wikimedia-common.incl':
        ensure  => present,
        content => template('mediawiki/apache/sites/wikimedia-common.incl.erb'),
        before  => Service['apache2'],
    }

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

    file { '/etc/apache2/sites-enabled/wikidata-uris.incl':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/sites/wikidata-uris.incl',
        before => Service['apache2'],
    }

    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    class { 'mediawiki::web::portals':
        portal_dir => $portal_dir,
    }

}
