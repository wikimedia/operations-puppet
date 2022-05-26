# SPDX-License-Identifier: Apache-2.0
# @summary rceate a cfssl dg config file
# @param driver which sql driver to use
# @param username the username to use for the specified driver
# @param password the password to use for the specified driver
# @param dbname the database name to use for the specified driver
# @param host the hostname to use for the specified driver
# @param host the hostname to use for the specified driver
# @param nofiy_service the Service to c$notify when significant changes have been made
# @param conf_file override the default location of the config file
# @param sqlite_path if using sqlite driver override the path of the db file
# @param python_config if true also write out a python config file, used by ocsp db scripts
define cfssl::db (
    Cfssl::DB_driver           $driver            = 'sqlite3',
    String                     $username          = 'cfssl',
    Sensitive[String[1]]       $password          = Sensitive('changeme'),
    String                     $dbname            = 'cfssl',
    Stdlib::Host               $host              = 'localhost',
    Stdlib::Port               $port              = 3306,
    String                     $dbcharset         = 'utf8mb4',
    Boolean                    $python_config     = false,
    Boolean                    $ssl_checkhostname = false,
    Optional[String]           $notify_service    = undef,
    Optional[Stdlib::Unixpath] $ssl_ca            = undef,
    Optional[Stdlib::Unixpath] $conf_file         = undef,
    Optional[Stdlib::Unixpath] $sqlite_path       = undef,
) {
    include cfssl
    $_conf_file = pick($conf_file, "${cfssl::conf_dir}/db.conf")
    $_sqlite_path = pick($sqlite_path, "${cfssl::conf_dir}/cfssl_sqlite.db")
    $db_data_source = $driver ? {
        # for now we need to unwrap the sensitive value otherwise it is not interpreted
        # Related bug: PUP-8969
        'mysql' => "${username}:${password.unwrap}@tcp(${host}:${port})/${dbname}?parseTime=true&tls=skip-verify",
        default => $_sqlite_path,
    }
    if $python_config {
        $ssl = $ssl_ca ? {
            undef   => {'check_hostname' => $ssl_checkhostname},
            default => {'ca' => $ssl_ca, 'check_hostname' => $ssl_checkhostname},
        }
        $config = {
            'host'     => $host,
            'port'     => $port,
            'user'     => $username,
            'password' => $password.unwrap,
            'db'       => $dbname,
            'charset'  => $dbcharset,
            'ssl'      => $ssl,
        }
        file {"${_conf_file}.json":
            ensure    => file,
            owner     => 'root',
            group     => 'root',
            mode      => '0440',
            show_diff => false,
            content   => Sensitive($config.to_json()),
        }
    }
    $db_config = {'driver' => $driver, 'data_source' => $db_data_source}
    $_notify_service = $notify_service ? {
      undef   => undef,
      default => Service[$notify_service],
    }
    file{$conf_file:
        ensure    => file,
        owner     => 'root',
        group     => 'root',
        mode      => '0440',
        show_diff => false,
        content   => Sensitive($db_config.to_json()),
        notify    => $_notify_service,
        require   => Package[$cfssl::packages],
    }
    if $driver == 'sqlite3' {
        sqlite::db {"cfssl ${title} signer DB":
            db_path    => $_sqlite_path,
            sql_schema => "${cfssl::sql_dir}/sqlite_initdb.sql",
            require    => File["${cfssl::sql_dir}/sqlite_initdb.sql"],
            before     => $_notify_service,
        }
    }
}
