class role::snapshot::common {
    include groups::wikidev

    include admins::roots
    include admins::mortals
    include accounts::datasets
    include sudo::appserver
}

class role::snapshot::cron::primary {
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
        user   => 'backup',
    }
    class { 'snapshot::dumps::mediadirlists':
        enable => true,
        user   => 'datasets',
    }
}

class role::snapshot::cron::secondary {
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
        user   => 'backup',
    }
    class { 'snapshot::dumps::mediadirlists':
        enable => false,
        user   => 'datasets',
    }
}
