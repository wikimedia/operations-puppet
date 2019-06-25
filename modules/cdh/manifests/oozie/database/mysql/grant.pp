# == Define cdh::oozie::database::mysql::grant
# Adds an additional grant for $cdh::oozie::database::mysql to
# allow connecting from a remote host.
#
# This does not create a new user or password, it just allows
# a remote host to connect to MySQL via the already configured
# user.  This is useful if running oozie server daemon on a node
# other than the MySQL host.
#
# == Usage:
# cdh::oozie::database::mysql::grant { 'myotherhost.example.org': }
#
define cdh::oozie::database::mysql::grant($allowed_host = $title) {
    Class['cdh::oozie::database::mysql'] -> Cdh::Oozie::Database::Mysql::Grant[$title]

    $jdbc_database = $cdh::oozie::database::mysql::jdbc_database
    $jdbc_username = $cdh::oozie::database::mysql::jdbc_username
    $jdbc_password = $cdh::oozie::database::mysql::jdbc_password

    # Only use -u or -p flag to mysql commands if
    # root username or root password are set.
    $username_option = $cdh::oozie::database::mysql::db_root_username ? {
        undef   => '',
        default => "-u'${cdh::oozie::database::mysql::db_root_username}'",
    }
    $password_option = $cdh::oozie::database::mysql::db_root_password ? {
        undef   => '',
        default => "-p'${cdh::oozie::database::mysql::db_root_password}'",
    }

    exec { "oozie_mysql_grant_${allowed_host}":
        command => "/usr/bin/mysql ${username_option} ${password_option} -e \"
GRANT ALL PRIVILEGES ON ${jdbc_database}.* TO '${jdbc_username}'@'${allowed_host}' IDENTIFIED BY '${jdbc_password}';
FLUSH PRIVILEGES;\"",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e \"SHOW GRANTS FOR '${jdbc_username}'@'${allowed_host}'\" | grep -q \"TO '${jdbc_username}'\"",
        user    => 'root',
    }
}
