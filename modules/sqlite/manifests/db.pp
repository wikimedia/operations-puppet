# @summary define to create and manage sqlite db
define sqlite::db (
    Wmflib::Ensure             $ensure     = 'present',
    String                     $owner      = 'root',
    String                     $group      = 'root',
    Stdlib::Filemode           $mode       = '0660',
    Optional[Stdlib::Unixpath] $db_path    = undef,
    Optional[Stdlib::Unixpath] $sql_schema = undef,
) {
    include sqlite
    $_db_path = $db_path ? {
        undef   => "${sqlite::default_db_path}/${title}.db",
        default => $db_path,
    }
    file {$_db_path:
        ensure => $ensure,
        owner  => $owner,
        group  => $group,
    }
    if $sql_schema {
        exec{"sqlite_initialist_db_${title}":
            path        => ['/bin', '/usr/bin'],
            user        => $owner,
            group       => $group,
            command     => "cat ${sql_schema} | ${sqlite::sqlite_cmd} ${_db_path}",
            refreshonly => true,
            subscribe   => File[$_db_path],
        }
    }
}
