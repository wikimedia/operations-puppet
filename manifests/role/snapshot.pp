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

    class { 'snapshot::cron::wikidatadumps::json':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::cron::wikidatadumps::ttl':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::cron::centralauthdump':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::cron::pagetitles':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::addschanges':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::cron::dumplists':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::cron::mediaperprojectlists':
        enable => true,
        user   => 'datasets',
    }
    class { 'snapshot::cron::cirrussearch':
        enable => true,
        user   => 'datasets',
    }
}

class role::snapshot::cron::secondary {
    include role::snapshot::common

    class { 'snapshot::cron::wikidatadumps::json':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::wikidatadumps::ttl':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::centralauthdump':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::pagetitles':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::addschanges':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::dumplists':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::mediadirlists':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::cirrussearch':
        enable => false,
        user   => 'datasets',
    }
}

class role::snapshot::dumps::hugewikis {
    include role::snapshot::common
    class { 'snapshot::dumps::cron::huge':
        user   => 'datasets',
    }
}

class role::snapshot::dumps::regularwikis {
    include role::snapshot::common
    class { 'snapshot::dumps::cron::rest':
        user   => 'datasets',
    }
}
