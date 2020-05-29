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

    class { '::snapshot::cron::commonsdumps::rdf':
        user      => $user,
# This disables the actual cron running for now, should be removed when scripts are ready
        filesonly => true,
    }
}
