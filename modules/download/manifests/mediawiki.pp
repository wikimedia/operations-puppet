class download::mediawiki {

    system::role { 'download::mediawiki': description => 'MediaWiki download' }

    package { 'apache':
        ensure => present,
    }

    apache::site { 'download.wikimedia.org':
        content => template('downloads/apache.conf.erb'),
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
