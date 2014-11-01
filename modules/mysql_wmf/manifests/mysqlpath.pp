class mysql_wmf::mysqlpath {
    file { '/etc/profile.d/mysqlpath.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mysql_wmf/mysqlpath.sh',
    }
}

