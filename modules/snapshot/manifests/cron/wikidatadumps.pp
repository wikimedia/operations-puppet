class snapshot::cron::wikidatadumps(
    $user      = undef,
    $group     = undef,
    $filesonly = false,
) {
    class {'::snapshot::cron::wikidatadumps::common':
        user  => $user,
        group => $group,
    }
    class { '::snapshot::cron::wikidatadumps::json':
        user      => $user,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::wikidatadumps::rdf':
        user      => $user,
        filesonly => $filesonly,
    }
}
