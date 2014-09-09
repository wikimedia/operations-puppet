# backups (amanda transitioning to bacula)
#

# Transitioning to bacula stanzas

define backup::set($jobdefaults=$backup::host::jobdefaults) {
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

class backup::host($pool='production') {
    include role::backup::config

    class { 'bacula::client':
        director       => $role::backup::config::director,
        catalog        => 'production',
        file_retention => '90 days',
        job_retention  => '6 months',
    }

    # This will use uniqueid fact to distribute (hopefully evenly) machines on
    # days of the week
    $days = $role::backup::config::days
    $day = inline_template('<%= @days[[@uniqueid].pack("H*").unpack("L")[0] % 7] -%>')

    $jobdefaults = "Monthly-1st-${day}-${pool}"

    Bacula::Client::Job <| |> {
        require => Class['bacula::client'],
    }
    File <| tag == 'backup-motd' |>

    # If the machine includes base::firewall then let director connect to us
    ferm::rule { 'bacula_director':
        rule => "proto tcp dport 9102 { saddr ${role::backup::config::director_ip} ACCEPT; }"
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
                        $jobdefaults=$backup::host::jobdefaults,
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

# TODO: Deprecate all of this before 2013-01-01
class backup::server {

    package { [ "amanda-common", "amanda-server" ]:
        ensure => latest;
    }

    file {
    "/var/backups/.ssh/authorized_keys":
        owner  => backup,
        group  => backup,
        mode   => 0600,
        source => "puppet:///private/backup/ssh-keys/authorized_keys_server";
    "/var/backups/.ssh/amanda_restore":
        owner  => backup,
        group  => backup,
        mode   => 0600,
        source => "puppet:///private/backup/ssh-keys/amanda_restore";
    "/etc/amanda/create_vtapes.sh":
        owner  => root,
        group  => root,
        mode   => 0700,
        source => "puppet:///files/backup/create_vtape.sh";
    }
    File <<| tag == "backup_host" |>>

    #service { xinetd:
    #    ensure => stopped;
    #}

    cron {
        amanda_daily:
        ensure  => absent,
        command => "/usr/sbin/amdump Wikimedia-Daily",
        require => Package["amanda-server"],
        user    => backup,
        hour    => 2,
        minute  => 0;

        amanda_weekly:
        ensure  => absent,
        command => "/usr/sbin/amdump Wikimedia-Weekly",
        require => Package["amanda-server"],
        user    => backup,
        hour    => 6,
        minute  => 0,
        weekday => Sunday;

        amanda_monthly:
        ensure  => absent,
        command  => "/usr/sbin/amdump Wikimedia-Monthly",
        require  => Package["amanda-server"],
        user     => backup,
        hour     => 12,
        minute   => 0,
        monthday => 1;
    }

    include backup::server::daily
    include backup::server::weekly
    include backup::server::monthly

}

class backup::server::daily {
    $mailto_account  = "ops@wikimedia.org"
    $cycle_type      = "Wikimedia-Daily"
    $vtapes_location = "/data/amanda/Wikimedia-Daily"
    $conf_location   = "/etc/amanda/Wikimedia-Daily"
    $tape_length     = "200 gbytes"
    $tape_num        = 6
    $dumpcycle       = "6 days"
    $runspercycle    = 1
    $tapecycle       = "6 tapes"
    $incr_type       = "incronly"
    $backup_priority = "high"
    $compress_type   = "client fast"

    file {
    "$conf_location":
        ensure  => absent,
        recurse => true,
        require => Package["amanda-server"],
    }
}

class backup::server::weekly {
    $mailto_account  = "ops@wikimedia.org"
    $cycle_type      = "Wikimedia-Weekly"
    $vtapes_location = "/data/amanda/Wikimedia-Weekly"
    $conf_location   = "/etc/amanda/Wikimedia-Weekly"
    $tape_length     = "200 gbytes"
    $tape_num        = 4
    $dumpcycle       = "4 weeks"
    $runspercycle    = 1
    $tapecycle       = "4 tapes"
    $incr_type       = "standard"
    $backup_priority = "medium"
    $compress_type   = "client fast"

    file {
    "$conf_location":
        ensure  => absent,
        recurse => true,
        require => Package["amanda-server"],
    }
}

class backup::server::monthly {
    $mailto_account  = "ops@wikimedia.org"
    $cycle_type      = "Wikimedia-Monthly"
    $vtapes_location = "/data/amanda/Wikimedia-Monthly"
    $conf_location   = "/etc/amanda/Wikimedia-Monthly"
    $tape_length     = "200 gbytes"
    $tape_num        = 12
    $dumpcycle       = "365 days"
    $runspercycle    = 1
    $tapecycle       = "12 tapes"
    $incr_type       = "noinc"
    $backup_priority = "low"
    $compress_type   = "client best"

    file {
    "$conf_location":
        ensure  => absent,
        recurse => true,
        require => Package["amanda-server"],
    }
}

class backup::client {

    define client_backup($host=$hostname, $path) {
        $line_of_text = "$host $path default"
        @@file { "/etc/amanda/disklist":
            ensure  => absent,
            owner   => root,
            group   => root,
            content => $line_of_text,
            tag     => "backup_host";
        }
    }

    $backup_server = "tridge.wikimedia.org"
    $backup_name   = "Wikimedia-Daily"
    $ssh_key_location = "/var/backups/.ssh/id_rsa"

    package { ["amanda-common", "amanda-client" ]:
        ensure => purged;
    }

    file {
    "/etc/amanda/":
        ensure  => absent,
        recurse => true;
    "/etc/amandahosts":
        ensure  => absent;
    "/var/backups/.amandahosts":
        ensure  => absent;
    "/var/backups/":
        ensure  => absent,
        recurse => true;
    }
    #service { xinetd:
    #    ensure => stopped;
    #}
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
