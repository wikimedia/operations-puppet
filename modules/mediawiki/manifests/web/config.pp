class mediawiki::web::config ($use_local_resources = true, $hhvm = false) {
    tag 'mediawiki', 'mw-apache-config'

    # Migrate mods enabling from the apache2.conf file to apache::mod_conf

    include apache::mod::autoindex
    include apache::mod::dir
    include apache::mod::setenvif
    if ! $hhvm {
        include apache::mod::php5
    } else {
        include apache::mod::fastcgi
        fail('HHVM is not supported yet!')
    }
    include apache::mod::authz_host
    include apache::mod::expires
    include apache::mod::rewrite
    include apache::mod::headers
    include apache::mod::alias
    include apache::mod::mime
    include apache::mod::status
    include apache::mod::version

    # check this conf against a standard debian one, maybe include our tokens etc with a wikimedia apache::conf

    file { '/etc/apache2/apache2.conf':
        content => template('mediawiki/apache/apache2.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Class['::mediawiki::web::config'],
        before  => Service['apache'],
    }

    file { '/etc/apache2/mods-available/expires.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/expires.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache']
    }

    file_line { '/etc/apache2/mods-available/alias.conf':
        ensure => present,
        line   => '        Options -Indexes MultiViews',
        match  => 'Options FollowSymlinks',
        notify => Service['apache']
    }

    file { '/etc/apache2/mods-available/setenvif.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/setenvif.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache']
    }

    file { '/etc/apache2/mods-available/mime.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/mime.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache']
    }


    # TODO: remove this? It's not used anywhere AFAICT
    file { '/etc/apache2/mods-available/userdir.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/userdir.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    apache2::conf { 'mediawiki-base':
        ensure => present,
        priority => '00',
        source => 'puppet:///modules/mediawiki/apache/mediawiki-base.conf'
    }

    # Now the sites, in strict sequence
    apache2::site { 'nonexistent':
        ensure   => present,
        priority => '00',
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf'
    }

    apache2::site { 'wwwportals':
        ensure   => present,
        priority => '01',
        source   => 'puppet:///modules/mediawiki/apache/sites/wwwportals.conf'
    }

    apache2::site { 'redirects':
        # TODO: should we generate  on-server from puppet?
        # I don't think so. In that case, things should be handled
        # with ori's ruby version of the redirect generating script.
        ensure   => present,
        priority => '02',
        source   => 'puppet:///modules/mediawiki/apache/sites/redirects.conf'
    }

    apache2::site { 'main':
        ensure   => present,
        priority => '03',
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf'
    }

    apache2::site { 'remnant':
        ensure   => present,
        priority => '04',
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf'
    }

    apache2::site { 'search.wikimedia':
        ensure   => present,
        priority => '05',
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf'
    }

    apache2::site { 'secure.wikimedia':
        ensure   => present,
        priority => '06',
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf'
    }

    apache2::site { 'wikimania':
        ensure   => present,
        priority => '07',
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf'
    }

    apache2::site { 'wikimedia':
        ensure   => present,
        priority => '08',
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf'
    }

    apache2::site { 'foundation':
        ensure   => present,
        priority => '09',
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf'
    }

}
