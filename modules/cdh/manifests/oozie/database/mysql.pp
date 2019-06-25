# == Class cdh::oozie::database::mysql
# Configures and sets up a MySQL database for Oozie.
#
# Note that this class does not support running
# the Oozie database on a different host than where your
# oozie server will run.  Permissions will only be granted
# for localhost MySQL users, so oozie server must run on this node.
#
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_oozie_configure.html
#
# == Parameters
# $db_root_username    - username for metastore database creation commands. Default: undef
# $db_root_password    - password for metastore database creation commands.
# $jdbc_database       - database name. Default: 'oozie'
# $jdbc_username       - username to access the Oozie database. Default: 'oozie'
# $jdbc_password       - password to access the Oozie database. Default: 'oozie'
#
class cdh::oozie::database::mysql(
    $db_root_username = undef,
    $db_root_password = undef,
    $jdbc_database    = 'oozie',
    $jdbc_username    = 'oozie',
    $jdbc_password    = 'oozie',
) {
    # Only use -u or -p flag to mysql commands if
    # root username or root password are set.
    $username_option = $db_root_username ? {
        undef   => '',
        default => "-u'${db_root_username}'",
    }
    $password_option = $db_root_password? {
        undef   => '',
        default => "-p'${db_root_password}'",
    }

    # oozie is going to need an oozie database and user.
    exec { 'oozie_mysql_create_database':
        path    => '/usr/local/bin:/usr/bin:/bin',
        command => "mysql ${username_option} ${password_option} -e \"
CREATE DATABASE ${jdbc_database};
CREATE USER '${jdbc_username}'@'localhost' IDENTIFIED BY '${jdbc_password}';
GRANT ALL PRIVILEGES ON ${jdbc_database}.* TO '${jdbc_username}'@'localhost' IDENTIFIED BY '${jdbc_password}';\"",
        unless  => "mysql ${username_option} ${password_option} -BNe 'SHOW DATABASES' | grep -q ${jdbc_database}",
        user    => 'root',
    }
}
