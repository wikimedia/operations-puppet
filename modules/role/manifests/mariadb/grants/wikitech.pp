class role::mariadb::grants::wikitech {

    include passwords::misc::scripts
    $wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
    $keystoneconfig  = hiera_hash('keystoneconfig', {})
    $oathreader_pass = $keystoneconfig['oath_dbpass']

    file { '/etc/mysql/grants-wikitech.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/grants-wikitech.sql.erb'),
    }
}

