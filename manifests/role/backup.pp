# A set of roles for the backup director, storage and client as they are
# configured in WMF

class role::backup::config {
    # if you change the director host name
    # you (likely) also need to change the IP,
    # we don't want to rely on DNS in firewall rules
    $director    = 'helium.eqiad.wmnet'
    $director_ip = '10.64.0.179'
    $director_ip6 = '2620:0:861:101:10:64:0:179'
    $database = 'm1-master.eqiad.wmnet'
    $days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    $pool = 'production'
    $offsite_pool = 'offsite'
    $onsite_sd = 'helium'
    $offsite_sd = 'heze'
}

class role::backup::host {
    include role::backup::config

    $pool = $role::backup::config::pool

    class { 'bacula::client':
        director       => $role::backup::config::director,
        catalog        => 'production',
        file_retention => '60 days',
        job_retention  => '60 days',
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
    ferm::service { 'bacula-file-demon':
        proto => 'tcp',
        port  => '9102',
        srange => "(${role::backup::config::director_ip} ${role::backup::config::director_ip6})",
    }
}

class role::backup::director {
    include role::backup::host
    include role::backup::config
    include passwords::bacula
    require geowiki::params
    $pool = $role::backup::config::pool
    $offsite_pool = $role::backup::config::offsite_pool
    $onsite_sd = $role::backup::config::onsite_sd
    $offsite_sd = $role::backup::config::offsite_sd

    system::role { 'role::backup::director': description => 'Backup server' }

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    # One pool for all
    bacula::director::pool { $pool:
        max_vols         => 50,
        storage          => "${onsite_sd}-FileStorage1",
        volume_retention => '60 days',
        label_fmt        => $pool,
        max_vol_bytes    => '536870912000',
        next_pool        => $offsite_pool,
    }

    # Default pool needed internally by bacula
    bacula::director::pool { 'Default':
        max_vols         => 1,
        storage          => "${onsite_sd}-FileStorage1",
        volume_retention => '1800 days',
    }

    # Archive pool for long term archival.
    bacula::director::pool { 'Archive':
        max_vols         => 5,
        storage          => "${onsite_sd}-FileStorage2",
        volume_retention => '5 years',
        label_fmt        => 'archive',
        max_vol_bytes    => '536870912000',
    }

    # Off site pool for off site backups
    bacula::director::pool { $offsite_pool:
        max_vols         => 50,
        storage          => "${offsite_sd}-FileStorage1",
        volume_retention => '60 days',
        label_fmt        => $offsite_pool,
        max_vol_bytes    => '536870912000',
    }

    # One schedule per day of the week.
    # Setting execution times so that it is unlikely jobs will run concurrently
    # with cron.{hourly,daily,monthly} or other cronscripts
    backup::schedule { $role::backup::config::days:
        pool    => $pool,
    }
    backup::weeklyschedule { $role::backup::config::days:
        pool    => $pool,
    }

    bacula::director::catalog { 'production':
        dbname     => 'bacula',
        dbuser     => 'bacula',
        dbhost     => $role::backup::config::database,
        dbport     => '3306',
        dbpassword => $passwords::bacula::database
    }

    # This has been taken straight from old files/backup/disklist-*
    bacula::director::fileset { 'root':
        includes     => [ '/' ]
    }
    bacula::director::fileset { 'a-sqldata':
        includes     => [ '/a/sqldata' ]
    }
    bacula::director::fileset { 'a-backup':
        includes => [ '/a/backup' ]
    }
    bacula::director::fileset { 'a-eventlogging':
        includes => [ '/a/eventlogging' ]
    }
    bacula::director::fileset { 'a-geowiki-data-private-bare':
        includes => [ $::geowiki::params::private_data_bare_path ]
    }
    bacula::director::fileset { 'home':
        includes => [ '/home' ]
    }
    bacula::director::fileset { 'mnt-a':
        includes => [ '/mnt/a' ]
    }
    bacula::director::fileset { 'roothome':
        includes => [ '/root' ]
    }
    bacula::director::fileset { 'srv-autoinstall':
        includes => [ '/srv/autoinstall' ]
    }
    bacula::director::fileset { 'srv-tftpboot':
        includes => [ '/srv/tftpboot' ]
    }
    bacula::director::fileset { 'srv-wikimedia':
        includes => [ '/srv/wikimedia' ]
    }
    bacula::director::fileset { 'srv-org-wikimedia':
        includes => [ '/srv/org/wikimedia' ]
    }
    bacula::director::fileset { 'var-lib-archiva':
        includes     => [ '/var/lib/archiva' ],
    }
    bacula::director::fileset { 'var-lib-jenkins-config':
        includes     => [ '/var/lib/jenkins/config.xml' ],
    }
    bacula::director::fileset { 'var-lib-gerrit2-review_site-git':
        includes => [ '/var/lib/gerrit2/review_site/git' ]
    }
    bacula::director::fileset { 'var-lib-jenkins-backups':
        includes => [ '/var/lib/jenkins/backups' ]
    }
    bacula::director::fileset { 'var-lib-mailman':
        includes => [ '/var/lib/mailman' ]
    }
    bacula::director::fileset { 'var-lib-puppet-ssl':
        includes => [ '/var/lib/puppet/ssl' ]
    }
    bacula::director::fileset { 'var-lib-puppet-volatile':
        includes => [ '/var/lib/puppet/volatile' ]
    }
    bacula::director::fileset { 'var-opendj-backups':
        includes => [ '/var/opendj/backups' ]
    }
    bacula::director::fileset { 'var-vmail':
        includes => [ '/var/vmail' ]
    }
    bacula::director::fileset { 'mysql-srv-backups':
        includes => [ '/srv/backups' ]
    }
    bacula::director::fileset { 'var-lib-carbon-whisper':
        includes => [ '/var/lib/carbon/whisper' ]
    }
    bacula::director::fileset { 'var-lib-ganglia':
        includes => [ '/var/lib/ganglia' ]
    }
    bacula::director::fileset { 'srv-ganglia':
        includes => [ '/srv/ganglia' ]
    }
    bacula::director::fileset { 'bugzilla-static':
        includes => [ '/srv/org/wikimedia/static-bugzilla' ]
    }
    bacula::director::fileset { 'bugzilla-backup':
        includes => [ '/srv/org/wikimedia/bugzilla-backup' ]
    }
    # As all /a this will hopefully no longer be needed at some point and will
    # be killed with fire
    bacula::director::fileset { 'mysql-a-backups':
        includes => [ '/a/backups' ]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-itrue',]
    }
    bacula::director::fileset { 'bpipe-mysql-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'bpipe-mysql-xfalse-ptrue-itrue'],
    }
    bacula::director::fileset { 'var-lib-grafana':
        includes => [ '/var/lib/grafana' ],
    }
    bacula::director::fileset { 'srv-phab-repos':
        includes => [ '/srv/phab/repos' ],
    }

    # The console should be on the director
    class { 'bacula::console':
        director   => $::fqdn,
    }

    nrpe::monitor_service { 'bacula_director':
        description  => 'bacula director process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-dir',
    }

    ferm::service { 'bacula-director':
        proto  => 'tcp',
        port   => '9101',
        srange => '$ALL_NETWORKS',
    }

}

class role::backup::storage() {
    include role::backup::config
    include base::firewall

    system::role { 'role::backup::storage': description => 'Backup Storage' }

    mount { '/srv/baculasd1' :
        ensure  => mounted,
        device  => '/dev/mapper/bacula-baculasd1',
        fstype  => 'ext4',
        require => File['/srv/baculasd1'],
    }

    mount { '/srv/baculasd2' :
        ensure  => mounted,
        device  => '/dev/mapper/bacula-baculasd2',
        fstype  => 'ext4',
        require => File['/srv/baculasd2'],
    }

    class { 'bacula::storage':
        director           => $role::backup::config::director,
        sd_max_concur_jobs => 5,
        sqlvariant         => 'mysql',
    }

    # We have two storage devices to overcome any limitations from backend
    # infrastructure (e.g. Netapp used to have only < 16T volumes)
    file { ['/srv/baculasd1',
            '/srv/baculasd2' ]:
        ensure  => directory,
        owner   => 'bacula',
        group   => 'bacula',
        mode    => '0660',
        require => Class['bacula::storage'],
    }

    bacula::storage::device { 'FileStorage1':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/baculasd1',
        max_concur_jobs => 2,
    }

    bacula::storage::device { 'FileStorage2':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/baculasd2',
        max_concur_jobs => 2,
    }

    nrpe::monitor_service { 'bacula_sd':
        description  => 'bacula sd process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-sd',
    }

    ferm::service { 'bacula-storage-demon':
        proto  => 'tcp',
        port   => '9103',
        srange => '$ALL_NETWORKS',
    }
}
