class snapshot::cron(
    $miscdumpsuser = undef,
    $group         = undef,
    $filesonly     = false,
    $php           = undef,
) {
    file { '/usr/local/etc/dump_functions.sh':
        ensure => 'present',
        path   => '/usr/local/etc/dump_functions.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dump_functions.sh',
    }

    class { '::snapshot::cron::configure':
        php => $php,
    }

    class { '::snapshot::cron::mediaperprojectlists':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::pagetitles':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::cirrussearch':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::categoriesrdf':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::dump_global_blocks':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::contentxlation':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::cron::shorturls':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::addschanges':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    # this class does not do any dumps, it just sets up
    # requirements for any wikibase type dumps
    # it cannot be imply included in those dumps classes
    # because we need to pass in the user/group params
    class { '::snapshot::cron::wikibase':
        user  => $miscdumpsuser,
        group => $group,
    }

    # wikibase type dump
    class { '::snapshot::cron::wikidatadumps':
        user      => $miscdumpsuser,
        group     => $group,
        filesonly => $filesonly,
    }
}
