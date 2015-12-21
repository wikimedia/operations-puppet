define backup::mysqlset(
    $method           = 'bpipe',
    $xtrabackup       = true,
    $per_db           = false,
    $innodb_only      = false,
    $binlog           = true,
    $slave            = true,
    $local_dump_dir   = undef,
    $password_file    = undef,
    $mysql_binary     = undef,
    $mysqldump_binary = undef,
    $jobdefaults      = $role::backup::host::jobdefaults,
) {

    $allowed_methods = [ 'bpipe', 'predump' ]
    if !($method in $allowed_methods) {
        fail("${method} is not allowed")
    }

    if !defined(Package['pigz']) {
        package { 'pigz':
            ensure => present,
        }
    }
    if $method == 'predump' {
        $extras = {
                'ClientRunBeforeJob' => '/etc/bacula/scripts/predump',
        }
        $basefileset = regsubst(regsubst($local_dump_dir,'/',''),'/','-','G')
        $fileset = "mysql-${basefileset}"

        file { '/etc/bacula/scripts/predump':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0500',
            content => template('backups/mysql-predump.erb'),
        }

    } elsif $method == 'bpipe' {
        bacula::client::mysql-bpipe { "mysql-bpipe-x${xtrabackup}-p${per_db}-i${innodb_only}":
            per_database          => $per_db,
            xtrabackup            => $xtrabackup,
            mysqldump_innodb_only => $innodb_only,
            local_dump_dir        => $local_dump_dir,
            password_file         => $password_file,
            mysql_binary          => $mysql_binary,
            mysqldump_binary      => $mysqldump_binary,
        }
        $extras  = undef
        $fileset = "mysql-${method}-x${xtrabackup}-p${per_db}-i${innodb_only}"
    }

    if $jobdefaults != undef {
        @bacula::client::job { "mysql-${method}-${name}-${jobdefaults}":
            fileset     => $fileset,
            jobdefaults => $jobdefaults,
            extras      => $extras,
        }
    }
}
