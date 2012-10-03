class labs-bots::mysql {
    # Common stuff
    include labs-bots::common

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
            source => 'puppet:///modules/labs-bots/mysql/backup.sh',
            ensure => present
    }

    # Nightly backup cronjob
    cron {
        'backup-mysql':
            command => '/bin/sh /usr/local/bin/backup_mysql.sh &> /dev/null',
            user => root,
            minute => '0',
            hour => '1',
            ensure => present,
            require => File[ '/usr/local/bin/backup_mysql.sh']
    }

    # Write out a my.cnf file
    file {
        '/root/.my.cnf':
            content => "[client]\nuser=root\npass=puppet\n",
            ensure => present
    }

    # Remove any remote root logins, we don't want this, ever
    exec {
        'purge remote root mysql servers':
            command => '/usr/bin/mysql -Bse \'DELETE FROM mysql.user WHERE host != "127.0.0.1" AND host != "localhost" AND user = "root"; FLUSH PRIVILEGES;\'; exit 0'
    }
}
