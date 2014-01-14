class download::mediawiki {

    system::role { 'download::mediawiki': description => 'MediaWiki download' }

    package { 'apache':
        ensure => present,
    }

    file { '/etc/apache2/sites-available/download.mediawiki.org':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/downloads/apache/download.mediawiki.org',
    }

    file { '/srv/org/mediawiki':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/org/mediawiki/download':
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
    }

    apache_site { 'download.mediawiki.org': name => 'download.mediawiki.org' }
}
