class snapshot::dumps::systemdjobs(
    Wmflib::Ensure $ensure = absent,
    $user   = undef,
    $maxjobs = undef,
    $runtype = undef,
) {

    file { '/usr/local/bin/fulldumps.sh':
        path   => '/usr/local/bin/fulldumps.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/fulldumps.sh',
    }

    file { '/var/log/dumps':
      ensure => 'directory',
      path   => '/var/log/dumps',
      mode   => '0755',
      owner  => $user,
    }

    # fixme there is an implicit dependency on
    # wikidump.conf.dumps plus some stage files, make explicit

    systemd::timer::job { 'fulldumps-rest':
        ensure             => $ensure,
        description        => 'snapshot - full dumps - rest',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/usr/local/bin/fulldumps.sh 01 14 ${runtype} full ${maxjobs} silent",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-01..14 08,20:05:00'},
    }

    systemd::timer::job { 'partialdumps-rest':
        ensure             => $ensure,
        description        => 'snapshot - partial dumps - rest',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/usr/local/bin/fulldumps.sh 20 25 ${runtype} partial ${maxjobs} silent",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-20..25 08,20:05:00'},
    }
}
