class mysql_wmf::mysqluser {
    user {
        'mysql': ensure => 'present',
    }
}

