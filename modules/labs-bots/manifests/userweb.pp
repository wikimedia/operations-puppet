class labs::bots::userweb {
    # Common stuff
    include labs::bots::common;

    # Apache
    package {
        [ 'apache2', 'libapache2-mod-php5' ]:
            ensure => latest;
    }

    # mod_userdir
    apache_module { userdir: name => 'userdir' }

    # Sites
    apache_site {
        bots:
            name => 'bots.wmflabs.org',
            docroot => '/var/www/'
            require => [ Package[apache2] ];
        cluebot:
            name => 'report.cluebot.org',
            docroot => '/data/project/public_html/damian/'
            require => [ Package[apache2] ];
    }

    file {
        # User data
        '/data/project/public_html':
            ensure => directory;

        # Userdir config
        '/etc/apache2/mods-available/${title}.conf':
            source => 'puppet:///modules/labs-bots/userweb/userdir.conf',
            require => [ File['/data/project/public_html'], Package[apache2], Apache_module[userdir] ],
            notify => Class[webserver::apache::service];

        # Default site
        '/var/www/index.html':
            ensure => present,
            source => 'puppet:///modules/labs-bots/userweb/index.html';

        '/var/www/robots.txt':
            ensure => present,
            content => 'User-agent: *\nDisallow: /';

        # Update script
        '/usr/local/bin/update_userdirs.py':
            ensure => present,
            source => 'puppet:///modules/labs-bots/userweb/update.py';
    }

    # Apache service
    service {
        'apache2':
            require => [ Package[apache2], Apache_module[userdir] ],
            subscribe => [ Package[libapache2-mod-php5], Apache_module[userdir] ],
            ensure => running;
    }

    # Update cronjob
    cron {
        'update-userdir':
            command => '/usr/bin/python /usr/local/bin/update_userdirs.py',
            user => root,
            minute => '*/5',
            ensure => present,
            require => File[ '/usr/local/bin/update_userdirs.py'];
    }
}
