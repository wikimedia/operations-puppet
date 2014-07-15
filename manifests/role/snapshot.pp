class role::snapshot::common {
    include role::dataset::systemusers
    include sudo::appserver
}

class role::snapshot::cron::primary {
    include role::snapshot::common

    class { 'snapshot::wikidatajsondump':
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

    class { 'snapshot::wikidatajsondump':
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
