# wikiadmin, wikiuser
define profile::mariadb::grants::core(
    String                          $wikiadmin_pass = '',
    String                          $wikiuser_username = '',
    String                          $wikiuser_pass  = '',
){
    $shard = $title
    file { "/etc/mysql/production-grants-core-${title}.sql":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/mariadb/grants/production-core.sql.erb'),
    }

    ensure_resource('file', '/etc/mysql/production-grants-core.sql', {'ensure' => 'absent'})
}
