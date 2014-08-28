class download::mediawiki {

    system::role { 'download::mediawiki': description => 'MediaWiki download' }

    apache::site { 'download.mediawiki.org':
        content => template('download/download.mediawiki.org.erb'),
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

}
