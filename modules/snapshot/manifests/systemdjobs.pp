class snapshot::systemdjobs(
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
        source => 'puppet:///modules/snapshot/systemdjobs/dump_functions.sh',
    }

    class { '::snapshot::systemdjobs::configure':
        php => $php,
    }

    class { '::snapshot::systemdjobs::mediaperprojectlists':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::pagetitles':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::cirrussearch':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::categoriesrdf':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::contentxlation':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::shorturls':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::addschanges':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::dump_growth_mentorship':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
    # this class does not do any dumps, it just sets up
    # requirements for any wikibase type dumps
    # it cannot be imply included in those dumps classes
    # because we need to pass in the user/group params
    class { '::snapshot::systemdjobs::wikibase':
        user  => $miscdumpsuser,
        group => $group,
    }

    # wikibase type dumps
    class { '::snapshot::systemdjobs::wikidatadumps':
        user      => $miscdumpsuser,
        group     => $group,
        filesonly => $filesonly,
    }
    class { '::snapshot::systemdjobs::commonsdumps':
        user      => $miscdumpsuser,
        group     => $group,
        filesonly => $filesonly,
    }

    class { '::snapshot::systemdjobs::wikitechdumps':
        user      => $miscdumpsuser,
        filesonly => $filesonly,
    }
}
