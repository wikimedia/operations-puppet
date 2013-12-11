class subversion ($host){

    include viewvc,
        subversion::conversion

    # include webserver::php5

    package { [ 'libapache2-svn']:
        ensure => latest,
    }

    group { 'svn':
        ensure    => present,
        name      => 'svn',
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

    apache_site { 'svn':
        name   => 'svn',
        prefix => '000-'
    }

    apache_module { 'authz_svn': name => 'authz_svn' }

    ferm::rule { 'svn_80':
        rule => 'proto tcp dport 80 ACCEPT;'
    }
    ferm::rule { 'svn_443':
        rule => 'proto tcp dport 443 ACCEPT;'
    }

    exec { '/usr/bin/svn co file:///svnroot/mediawiki/USERINFO svnusers':
        creates => '/var/cache/svnusers/.svn',
        cwd     => '/var/cache',
        user    => 'www-data',
        require => File['/var/cache/svnusers'],
    }

    file { '/etc/apache2/sites-available/svn':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/subversion/apache/${host}",
    }
}

