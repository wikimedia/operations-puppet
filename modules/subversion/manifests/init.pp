class subversion ($host){

    include viewvc,
        subversion::conversion

    # include webserver::php5

    group { 'svn':
        ensure    => present,
        gid       => 550,
        alias     => 550,
        allowdupe => false,
    }

    file { '/usr/local/bin/sillyshell':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/subversion/sillyshell',
    }

    file { '/srv/org/wikimedia/svn':
        ensure  => directory,
        source  => 'puppet:///modules/subversion/docroot',
        owner   => 'root',
        group   => 'svnadm',
        mode    => '0664',
        recurse => true,
    }

    file { '/var/cache/svnusers':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    file { '/svnroot':
        ensure => directory,
        owner  => 'root',
        group  => 'svn',
        mode   => '0775';
    }

    include backup::host
    backup::set { 'svnroot': }


    include ::apache::mod::authz_svn

    exec { '/usr/bin/svn co file:///svnroot/mediawiki/USERINFO svnusers':
        creates => '/var/cache/svnusers/.svn',
        cwd     => '/var/cache',
        user    => 'www-data',
        require => File['/var/cache/svnusers'],
    }

    ::apache::site { $host:
        source => "puppet:///modules/subversion/apache/${host}",
    }
}
