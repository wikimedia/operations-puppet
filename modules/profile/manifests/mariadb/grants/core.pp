# wikiadmin, wikiuser
class profile::mariadb::grants::core {

    include passwords::misc::scripts

    $wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
    $wikiuser_pass  = $passwords::misc::scripts::wikiuser_pass

    file { '/etc/mysql/production-grants-core.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/mariadb/grants/production-core.sql.erb'),
    }
}
