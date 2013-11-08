class download::mediawiki {

    system::role { 'download::mediawiki': description => 'MediaWiki download' }

    # FIXME: require apache

    file {
        #apache config
        '/etc/apache2/sites-available/download.mediawiki.org':
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///files/apache/sites/download.mediawiki.org';
        '/srv/org/mediawiki':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0775';
        '/srv/org/mediawiki/download':
            ensure => directory,
            owner  => 'mwdeploy',
            group  => 'mwdeploy',
            mode   => '0775';
    }

    apache_site { 'download.mediawiki.org': name => 'download.mediawiki.org' }
}

