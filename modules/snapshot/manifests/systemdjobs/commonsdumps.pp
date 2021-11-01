class snapshot::systemdjobs::commonsdumps(
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

    class { '::snapshot::systemdjobs::commonsdumps::json':
        user      => $user,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::commonsdumps::rdf':
        user      => $user,
        filesonly => $filesonly,
    }
}
