class svn::server {
    system::role { 'svn::server': description => 'public SVN server' }

    include viewvc,
    conversion
    # include webserver::php5

    package { [ 'libsvn-notify-perl',
        'python-subversion',
        'libapache2-svn',
        'python-pygments',]:
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
        source => 'puppet:///modules/svn/sillyshell',
    }

    file { '/etc/apache2/sites-available/svn':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/svn/apache/svn.wikimedia.org',
    }

    file { '/srv/org/wikimedia/svn':
        ensure  => directory,
        source  => 'puppet:///modules/svn/docroot',
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

    apache_site { 'svn': name => 'svn', prefix => '000-' }
    apache_module { 'authz_svn': name => 'authz_svn' }

    monitor_service { 'https': description => 'HTTPS', check_command => 'check_ssl_cert!svn.wikimedia.org' }

    ferm::rule { 'svn_80':
        rule => 'proto tcp dport 80 ACCEPT;'
    }
    ferm::rule { 'svn_443':
        rule => 'proto tcp dport 443 ACCEPT;'
    }

    cron { 'svnuser_generation':
        command => '(cd /var/cache/svnusers && svn up) > /dev/null 2>&1',
        user    => 'www-data',
        hour    => 0,
        minute  => 0;
    }

    exec { '/usr/bin/svn co file:///svnroot/mediawiki/USERINFO svnusers':
        creates => '/var/cache/svnusers/.svn',
        cwd     => '/var/cache',
        user    => 'www-data',
        require => File['/var/cache/svnusers'],
    }
}

