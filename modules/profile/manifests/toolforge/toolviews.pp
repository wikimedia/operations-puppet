# == Class: profile::toolforge::toolviews
#
class profile::toolforge::toolviews (
    Boolean      $enabled        = lookup('profile::toolforge::toolviews::enabled',        {default_value => true}),
    Stdlib::Host $mysql_host     = lookup('profile::toolforge::toolviews::mysql_host',     {default_value => 'localhost'}),
    String       $mysql_db       = lookup('profile::toolforge::toolviews::mysql_db',       {default_value => 'example_db'}),
    String       $mysql_user     = lookup('profile::toolforge::toolviews::mysql_user',     {default_value => 'example_user'}),
    String       $mysql_password = lookup('profile::toolforge::toolviews::mysql_password', {default_value => 'example_passwd'}),
    String       $hash_salt      = lookup('profile::toolforge::toolviews::hash_salt',      {default_value => 'fakesalt'}),
){
    # due to wrong or missing DB credentials, toolviews will produce cronspam
    # if not running in the tools project. If you want to run this in toolsbeta
    # make sure you provide relevant hiera keys and update the following if:
    if $::wmcs_project == 'tools' {
        class { '::toolforge::toolviews':
            enabled        => $enabled,
            mysql_host     => $mysql_host,
            mysql_db       => $mysql_db,
            mysql_user     => $mysql_user,
            mysql_password => $mysql_password,
            hash_salt      => $hash_salt,
        }
    }
}
