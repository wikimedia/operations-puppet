class role::postgres::common {
    include standard

    $datadir = '/srv/postgres/9.4/main'

    file { '/etc/postgresql/9.4/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/postgres/tuning.conf',
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    ganglia::plugin::python { 'diskstat': }

    ferm::service { 'postgresql':
        proto  => 'tcp',
        port   => 5432,
        srange => '$INTERNAL',
    }
}

