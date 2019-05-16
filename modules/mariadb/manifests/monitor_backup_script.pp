# Installs the scripts and dependencies, but doesn't create new alerts
# (that is done on monitor_backup define)
class mariadb::monitor_backup_script {
    require_package(
        'python3-pymysql',  # to connect to the backup metadata db
        'python3-arrow',    # to print human-friendly dates
    )

    file { '/usr/local/bin/check_mariadb_backups.py':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/mariadb/check_mariadb_backups.py',
    }
}
