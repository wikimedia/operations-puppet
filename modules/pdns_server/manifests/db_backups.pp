# SPDX-License-Identifier: Apache-2.0
class pdns_server::db_backups(
) {
    if !defined(Class['pdns_server']) {
        notice('no pdns_server class defined?')
    }

    $db = 'pdns'
    $dbuser = 'dump'

    $statements = [
        {
            'stmt'              => "CREATE USER IF NOT EXISTS ${dbuser}@localhost IDENTIFIED VIA unix_socket",
            'unless'            => 'SELECT user, plugin FROM mysql.user',
            'unless_grep_match' => "${dbuser}[[:space:]]unix_socket",
        },
        {
            'stmt'              => "GRANT RELOAD, FILE, SUPER, REPLICATION CLIENT ON *.* TO \\`${dbuser}\\`@\\`localhost\\`",
            'unless'            => "SHOW GRANTS FOR '${dbuser}'@'localhost'",
            'unless_grep_match' => undef,  # will use the same stmt

        },
        {
            'stmt'              => "GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON \\`${db}\\`.* TO \\`${dbuser}\\`@\\`localhost\\`",
            'unless'            => "SHOW GRANTS FOR '${dbuser}'@'localhost'",
            'unless_grep_match' => undef,  # will use the same stmt
        },
    ].each |Integer $index, Hash $item| {
        dbutils::statement { "pdns_server_db_backups_stmt_${index}":
            statement         => $item['stmt'],
            unless            => $item['unless'],
            unless_grep_match => $item['unless_grep_match'],
        }
    }
}
