class snapshot::cron::commonsdumps(
    $user      = undef,
    $group     = undef,
    $filesonly = false,
) {
    file { '/var/log/commonsdump':
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    class { '::snapshot::cron::commonsdumps::json':
        user      => $user,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::commonsdumps::rdf':
        user      => $user,
        filesonly => $filesonly,
    }
}
