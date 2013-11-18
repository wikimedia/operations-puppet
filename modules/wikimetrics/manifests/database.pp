# == Class wikimetrics::database
#
# Note that this class does not support running
# the Wikimetrics datbase on a different host than where your
# queue and web services will run.  Permissions will only be granted
# for localhost MySQL users.  You will have to grant permissions
# for remote hosts to connect to MySQL and the wikimetrics database manually.
#
class wikimetrics::database(
    $db_pass = 'wikimetrics', # you should really change this one
    $db_name = 'wikimetrics',
    $db_user = 'wikimetrics',
    $db_host = 'localhost',
)
{
    if !defined(Package['mysql-server']) {
        package { 'mysql-server':
            ensure => 'installed',
        }
    }

    # wikimetrics is going to need a wikimetrics database and user.
    exec { 'wikimetrics_mysql_create_database':
        command => "/usr/bin/mysql -e \"CREATE DATABASE ${db_name}; USE ${db_name};\"",
        unless  => "/usr/bin/mysql -e 'SHOW DATABASES' | /bin/grep -q ${db_name}",
        user    => 'root',
    }
    exec { 'wikimetrics_mysql_create_user':
        command => "/usr/bin/mysql -e \"
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
CREATE USER '${db_user}'@'127.0.0.1' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;\"",
        unless  => "/usr/bin/mysql -e \"SHOW GRANTS FOR '${db_user}'@'127.0.0.1'\" | grep -q \"TO '${db_user}'\"",
        user    => 'root',
    }
}
