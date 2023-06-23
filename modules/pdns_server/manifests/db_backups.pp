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
            'stmt'              => "GRANT EVENT, LOCK TABLES, SELECT, SHOW VIEW, TRIGGER ON \\`${db}\\`.* TO \\`${dbuser}\\`@\\`localhost\\`",
            'unless'            => "SHOW GRANTS FOR '${dbuser}'@'localhost'",
            'unless_grep_match' => undef,  # will use the same stmt
        },
    ].each |Integer $index, Hash $item| {
        if $item['unless_grep_match'] {
            $unless_grep_match = $item['unless_grep_match']
        } else {
            $unless_grep_match = $item['stmt']
        }
        exec { "inject-pdns-db-backup-stmt-${index}":
            command => "/usr/bin/mysql -u root -Bs <<< \"${item['stmt']};\"",
            unless  => "/usr/bin/mysql -u root -Bs <<< \"${item['unless']};\" | grep -q \"${unless_grep_match}\"",
            user    => 'root',
            timeout => '30',
        }
    }
}
