class role::snapshot::common {
    include ::dataset::user
    include base::firewall

    # Allow SSH from deployment hosts
    ferm::rule { 'deployment-ssh':
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }
}

class role::snapshot {
    include role::snapshot::common

    include ::snapshot
    include ::snapshot::dumps

    system::role { 'role::snapshot':
        description => 'producer of XML dumps',
    }
}

class role::snapshot::dumps::monitor {
    include role::snapshot::common

    include ::snapshot
    include ::snapshot::dumps::monitor

    system::role { 'role::snapshot::dumps::monitor':
        description => 'monitor of XML dumps',
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
    class { 'snapshot::cirrussearch':
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
    class { 'snapshot::cirrussearch':
        enable => false,
        user   => 'datasets',
    }
}

class role::snapshot::dumps:hugewikis {
    include role::snapshot::common
    class { 'snapshot::dumps::cron::huge':
        user   => 'datasets',
    }
}

class role::snapshot::dumps:regularwikis {
    include role::snapshot::common
    class { 'snapshot::dumps::cron::rest':
        user   => 'datasets',
    }
}
