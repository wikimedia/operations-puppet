# = Class: profile::mariadb::generic_server
#
# Sets up a generic mysql (mariadb) server.
#
class profile::mariadb::generic_server (
    Stdlib::Unixpath $basedir = lookup(profile::mariadb::generic_server::basedir, {'default_value' => '/usr'}),
    Stdlib::Unixpath $datadir = lookup(profile::mariadb::generic_server::datadir, {'default_value' => '/srv/sqldata'}),
){

    class { '::mariadb::packages': }

    class { '::mariadb::config':
        basedir => $basedir,
        datadir => $datadir,
    }
}
