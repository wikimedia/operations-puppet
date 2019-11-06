# == Class: profile::toolforge::toolviews
#
# filtertags: labs-project-tools
class profile::toolforge::toolviews (
    $mysql_host     = lookup('profile::toolforge::toolviews::mysql_host',     {default_value => 'localhost'}),
    $mysql_db       = lookup('profile::toolforge::toolviews::mysql_db',       {default_value => 'example_db'}),
    $mysql_user     = lookup('profile::toolforge::toolviews::mysql_user',     {default_value => 'example_user'}),
    $mysql_password = lookup('profile::toolforge::toolviews::mysql_password', {default_value => 'example_passwd'}),
){
    class { '::toollabs::toolviews':
        mysql_host     => $mysql_host,
        mysql_db       => $mysql_db,
        mysql_user     => $mysql_user,
        mysql_password => $mysql_password,
    }
}
