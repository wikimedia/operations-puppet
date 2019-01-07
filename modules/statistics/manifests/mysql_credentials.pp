# = Define: statistics::mysql_credentials
# Sets up mysql credentials for a given user group to access
# the research dbs
define statistics::mysql_credentials(
    $group,
) {
    include ::passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/research-client.cnf.
    mariadb::config::client { $title:
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => $group,
        mode  => '0440',
    }
}
