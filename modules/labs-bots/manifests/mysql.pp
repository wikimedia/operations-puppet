class labs-bots::mysql {
    # Common stuff
    include labs-bots::common

    # MySQL server
    class {
        'generic::mysql::server':
            thread_stack => '192K',
            thread_cache_size => '8',

            query_cache_limit => '1M',
            query_cache_size => '16M',

            tmp_table_size => '64M',
            innodb_buffer_pool_size => '512M',
            key_buffer_size => '16M',

            max_allowed_packet => '16M',
            datadir => '/mnt/mysql',
            version => $::lsbdistrelease ? {
                '12.04' => '5.5',
                default => false,
            }
    }

    file {
        # Data dir
        '/mnt/data/':
            owner => 'mysql',
            group => 'mysql',
            mode => 700,
            ensure => directory;

        # Backup script
        '/usr/local/sbin/backup_mysql.sh':
            source => 'puppet:///modules/labs-bots/mysql/backup.sh',
            mode => 700,
            owner => 'root',
            group => 'root',
            ensure => present;

        # Query killer script
        '/usr/local/sbin/querykiller.pl':
            source => 'puppet:///modules/labs-bots/mysql/querykiller.pl',
            mode => 700,
            owner => 'root',
            group => 'root',
            ensure => present;
    }

    package {
        [ 'libdbi-perl' ]:
            ensure => latest;
    }

    cron {
        # Nightly backup cronjob
        'backup-mysql':
            command => '/bin/sh /usr/local/sbin/backup_mysql.sh &> /dev/null',
            user => root,
            minute => '0',
            hour => '1',
            ensure => present,
            require => File[ '/usr/local/sbin/backup_mysql.sh'];

        # query killer
        'mysql-querykiller':
            command => '/usr/bin/perl /usr/local/sbin/querykiller.pl &> /dev/null',
            user => root,
            ensure => present,
            require => File[ '/usr/local/sbin/querykiller.pl'];
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
