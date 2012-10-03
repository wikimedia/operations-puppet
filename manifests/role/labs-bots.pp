class role::labs::bots::common {
    # Language stuff needed for bots
    include generic::locales::international

    # Symlink for backwards compatibility
    file {
        '/mnt/public_html':
            ensure => 'link',
            target => '/data/project/public_html'
    }

    # TODO - any common packages on all instances
}

class role::labs::bots::application {
    # Common stuff
    include role::labs::bots::common

    # Standard application packages
    include generic::packages::git-core
    package {
        [ 'python3-minimal', 'python-virtualenv' ]:
            ensure => latest
    }

    # TODO - for things like mono do we want generic classes then
    # include packages::mono or such in here?
    # TODO - Add all standard software
}

class role::labs::bots::mysql {
    # Common stuff
    include role::labs::bots::common

    # MySQL server
    # TODO - add the correct buffer settings in here for a 4/8gb ram instance
    # and standardise the sql instances to this
    class {
        'generic::mysql::server':
            datadir => $::mysql_datadir ? {
                undef => '/mnt/mysql',
                default => $::mysql_datadir,
            },
            version => $::lsbdistrelease ? {
                '12.04' => '5.5',
                default => false,
            }
    }

    # Backup script
    file {
        '/usr/local/bin/backup_mysql.sh':
            source => 'puppet:///files/labs-bots/mysql/backup.sh',
            ensure => present
    }

    # Nightly backup cronjob
    cron {
        'backup-mysql':
            command => '/bin/sh /usr/local/bin/backup_mysql.sh',
            user => root,
            minute => '0',
            hour => '1',
            ensure => present,
            require => File[ '/usr/local/bin/backup_mysql.sh']
    }

    # Write out a my.cnf file
    file {
        '/root/.my.cnf':
            content => '[client]\nuser=root\npass=puppet\n',
            ensure => present
    }

    # Remove any remote root logins, we don't want this, ever
    exec {
        'purge remote root mysql servers':
            command => '/usr/bin/mysql -Bse \'DELETE FROM mysql.user WHERE host != "127.0.0.1" AND host != "localhost" AND user = "root"; FLUSH PRIVILEGES;\'; exit 0'
    }
}

class role::labs::bots::userweb {
    # Common stuff
    include role::labs::bots::common

    # Apache/PHP
    package { [ 'apache2', 'libapache2-mod-php5', 'php5', 'php5-cli', 'php5-mysql' ]:
        ensure => latest;
    }

    # Apache service
    service {
        apache2:
            require => [ Package[apache2] ],
            subscribe => [ Package[libapache2-mod-php5],
                            File["/etc/apache2/mods-enabled/userdir.conf"],
                            File["/etc/apache2/mods-enabled/userdir.load"],
                            File["/etc/apache2/conf.d/namevirtualhost"],
                            File["/etc/apache2/sites-enabled/000_default"],
                            File["/etc/apache2/sites-enabled/bots.wmflabs.org"],
                            File["/etc/apache2/sites-enabled/report.cluebot.org"] ],
            ensure => running;
    }

    file {
        # User data
        '/data/project/public_html':
            ensure => directory;

        # Userdir config
        '/etc/apache2/mods-enabled/userdir.conf':
            source => 'puppet:///files/labs-bots/userweb/userdir.conf';

        '/etc/apache2/mods-enabled/userdir.load':
            ensure => link,
            target => '../mods-available/userdir.load';

        # Default site
        '/var/www/index.html':
            ensure => present,
            source => 'puppet:///files/labs-bots/userweb/index.html';

        '/var/www/robots.txt':
            ensure => present,
            content => 'User-agent: *\nDisallow: /';

        # Update script
        '/usr/local/bin/update_userdirs.py':
            ensure => present,
            source => 'puppet:///files/labs-bots/userweb/update.py';

        # Name virtual host
        '/etc/apache2/conf.d/namevirtualhost':
            content => 'NameVirtualHost *:80',
            mode => 0440,
            owner => root,
            group => www-data;

        # vhosts
        '/etc/apache2/sites-enabled/000_default':
            ensure => absent;

        '/etc/apache2/sites-enabled/bots.wmflabs.org':
            require => [ Package[libapache2-mod-php5] ],
            source => 'puppet:///files/labs-bots/userweb/sites/bots.wmflabs.org',
            mode => 0440,
            owner => root,
            group => www-data;

        '/etc/apache2/sites-enabled/report.cluebot.org':
            require => [ Package[libapache2-mod-php5] ],
            source => 'puppet:///files/labs-bots/userweb/sites/report.cluebot.org',
            mode => 0440,
            owner => root,
            group => www-data;
    }

    # Update cronjob
    cron {
        'update-userdir':
            command => '/usr/bin/python /usr/local/bin/update_userdirs.py',
            user => root,
            minute => '*/5',
            ensure => present,
            require => File[ '/usr/local/bin/update_userdirs.py']
    }
}
