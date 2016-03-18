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
    class { 'snapshot::dumps::shorturls':
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
    class { 'snapshot::cron::mediaperprojectlists':
        enable => false,
        user   => 'datasets',
    }
    class { 'snapshot::cron::cirrussearch':
        enable => false,
        user   => 'datasets',
    }
}

