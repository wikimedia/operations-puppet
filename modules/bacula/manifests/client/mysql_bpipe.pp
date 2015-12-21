# Definition: bacula::client::mysql_bpipe
#
# This definition creates a bpipe plugin at the host specifying it
#
# Parameters:
#   $xtrabackup
#       Required (true, false). Whether xtrabackup or mysqldump will be used
#   $xbstream_dir
#       Required if xtrabackup is defined. Where xbstream will restore a backup.
#       It should could make sense for this to be on the same physical partition
#       as mysqld's datadir in order to minimize downtime
#   $per_database
#       Required (true, false). Whether backups will be taken per database or not
#   $pigz_level
#       pigz compression level. defaults to --fast (-1)
#   $is_slave
#       Whether the host to be backed-up is a slave in which case --dump-slave
#       is passed to mysqldump and --slave-info --safe-slave-backup to xtrabackup
#       Defaults to false
#   $mysqldump_innodb_only
#       Whether the database is comprised of innodb only tables so it is safe to
#       use --single-transaction. This defaults to false to err on the side of
#       caution
#   $password_file
#       A simple my.cnf style file containing the credentials for a valid
#       account to the database that can be used by mysql and mysqldump
#   $local_dump_dir
#       A simple my.cnf style file containing the credentials for a valid
#       account to the database that can be used by mysql and mysqldump
#   $mysql_binary
#       Path to mysql binary if you feel like overriding the default of
#       /usr/bin/mysql
#   $mysqldump_binary
#       Path to mysqldump binary if you feel like overriding the default of
#       /usr/bin/mysqldump
#
# Actions:
#       Will create a bpipe plugin for bacula
#
# Requires:
#       bacula::client
#
# Sample Usage:
#       bacula::client::mysql_bpipe { 'mybpipe':
#           per_database            => false,
#           xtrabackup              => true,
#           xbstream_dir            => '/var/tmp/xbstream',
#           mysqldump_innodb_only   => false,
#       }
#
define bacula::client::mysql_bpipe(
                $per_database,
                $xtrabackup,
                $xbstream_dir='/var/tmp/xbstream',
                $pigz_level='fast',
                $is_slave=false,
                $mysqldump_innodb_only=false,
                $password_file=undef,
                $local_dump_dir=undef,
                $mysql_binary='/usr/bin/mysql',
                $mysqldump_binary='/usr/bin/mysqldump',
                ) {
    file { "/etc/bacula/scripts/${name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => template('bacula/bpipe-mysql-db.erb'),
        require => Class['bacula::client'],
    }

    if $xtrabackup {
        if ! defined(Package['percona-xtrabackup']) {
            package { 'percona-xtrabackup':
                ensure  => installed,
            }
        }

        file { $xbstream_dir:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0440',
        }
    }
}
