define cfssl::db (
    Cfssl::DB_driver           $driver         = 'sqlite3',
    String                     $username       = 'cfssl',
    Sensitive[String[1]]       $password       = Sensitive('changeme'),
    String                     $dbname         = 'cfssl',
    Stdlib::Host               $host           = 'localhost',
    String                     $notify_service = 'cfssl-multirootca',
    Optional[Stdlib::Unixpath] $conf_file      = undef,
    Optional[Stdlib::Unixpath] $sqlite_path    = undef,
) {
    include cfssl
    $_conf_file = pick($conf_file, "${cfssl::conf_dir}/db.conf")
    $db_data_source = $driver ? {
        # for now we need to unwrap the sensitive value otherwise it is not interpreted
        # Related bug: PUP-8969
        'mysql' => "${username}:${password.unwrap}@tcp(${host}:3306)/${dbname}?parseTime=true&tls=skip-verify",
        default => $sqlite_path,
    }
    $db_config = {'driver' => $driver, 'data_source' => $db_data_source}
    file{$conf_file:
        ensure    => file,
        owner     => 'root',
        group     => 'root',
        mode      => '0440',
        show_diff => false,
        content   => Sensitive($db_config.to_json()),
        notify    => Service[$notify_service],
        require   => Package[$cfssl::packages],
    }
    if $driver == 'sqlite3' {
        $_sqlite_path = pick($sqlite_path, "${cfssl::conf_dir}/cfssl_sqlite.db")
        sqlite::db {"cfssl ${title} signer DB":
            db_path    => $_sqlite_path,
            sql_schema => "${cfssl::sql_dir}/sqlite_initdb.sql",
            require    => File["${cfssl::sql_dir}/sqlite_initdb.sql"],
            before     => Service[$notify_service],
        }
    }
}
