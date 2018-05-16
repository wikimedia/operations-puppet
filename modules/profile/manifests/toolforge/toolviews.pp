# == Class: profile::toolforge::toolviews
#
# filtertags: labs-project-tools
class profile::toolforge::toolviews (
    $mysql_host     = lookup('profile::toolforge::toolviews::mysql_host'),
    $mysql_db       = lookup('profile::toolforge::toolviews::mysql_db'),
    $mysql_user     = lookup('profile::toolforge::toolviews::mysql_user'),
    $mysql_password = lookup('profile::toolforge::toolviews::mysql_password'),
){
    class { '::toollabs::toolviews':
        mysql_host     => $mysql_host,
        mysql_db       => $mysql_db,
        mysql_user     => $mysql_user,
        mysql_password => $mysql_password,
    }
}
