class role::snapshot::common {
    include role::dataset::systemusers
    # The snapshot nodes do not include standard, so this is needed.
    # It also includes some duplication with other modules, and should really go away.
    file { '/etc/sudoers.d/appserver':
        ensure => present,
        path   => '/etc/sudoers.d/appserver',
        owner  => root,
        group  => root,
        mode   => '0440',
        source => 'puppet:///files/snapshot/sudoers.snapshot',
    }

}

class role::snapshot::cron::primary {
    include role::snapshot::common

    class { 'snapshot::wikidatadumps::json':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::wikidatadumps::ttl':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::centralauthdump':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::dumps::pagetitles':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::addschanges':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::dumps::dumplists':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::dumps::mediadirlists':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::mediaperprojectlists':
        enable => true,
        user   => 'datasets',
    }
}

class role::snapshot::cron::secondary {
    include role::snapshot::common

    class { 'snapshot::wikidatadumps::json':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::wikidatadumps::ttl':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::centralauthdump':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::dumps::pagetitles':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::addschanges':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::dumps::dumplists':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::dumps::mediadirlists':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::mediaperprojectlists':
        enable => false,
        user   => 'datasets',
    }
}
