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
    class { 'snapshot::dumps::shorturls':
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

