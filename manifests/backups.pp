# backup::set is probably what you want
define backup::set($jobdefaults=$role::backup::host::jobdefaults) {
    if $jobdefaults != undef {
        @bacula::client::job { "${name}-${jobdefaults}":
            fileset     => $name,
            jobdefaults => $jobdefaults,
        }

        $motd_content = "#!/bin/sh\necho \"Backed up on this host: ${name}\""
        @file { "/etc/update-motd.d/06-backups-${name}":
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => $motd_content,
            tag     => 'backup-motd',
        }
    }
}

define backup::mysqlset($method='bpipe',
                        $xtrabackup=true,
                        $per_db=false,
                        $innodb_only=false,
                        $local_dump_dir=undef,
                        $password_file=undef,
                        $mysql_binary=undef,
                        $mysqldump_binary=undef,
                        $jobdefaults=$role::backup::host::jobdefaults,
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
            ensure  => 'present',
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
        $extras = undef
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

# Utility definition used internally to deduplicate code
define backup::schedule($pool) {
    bacula::director::schedule { "Monthly-1st-${name}":
        runs => [
            { 'level' => 'Full',
              'at'    => "1st ${name} at 02:05",
            },
            { 'level' => 'Differential',
              'at'    => "3rd ${name} at 03:05",
            },
            { 'level' => 'Incremental',
              'at'    => 'at 04:05',
            },
                ],
    }

    bacula::director::jobdefaults { "Monthly-1st-${name}-${pool}":
        when => "Monthly-1st-${name}",
        pool => $pool,
    }

}
# Same for weekly backups
define backup::weeklyschedule($pool) {
    bacula::director::schedule { "Weekly-${name}":
        runs => [
            { 'level' => 'Full',
              'at'    => "${name} at 02:05",
            },
                ],
    }

    bacula::director::jobdefaults { "Weekly-${name}-${pool}":
        when => "Weekly-${name}",
        pool => $pool,
    }
}

class backup::mysql {
    file { "/usr/local/sbin/snaprotate.pl":
        owner  => root,
        group  => root,
        mode   => 0755,
        source => "puppet:///files/backup/snaprotate.pl";
    }

    cron { snaprotate:
        command => "/usr/local/sbin/snaprotate.pl -a swap -V tank -s data -L 20G -c 1",
        user    => root,
        hour    => 1,
        minute  => 0;
    }
}
