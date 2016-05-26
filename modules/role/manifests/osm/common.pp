class role::osm::common {
    include standard

    $datadir = '/srv/postgres/9.1/main'

    file { '/etc/postgresql/9.1/main/tuning.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        # lint:ignore:puppet_url_without_modules
        source => 'puppet:///files/osm/tuning.conf',
        # lint:endignore
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    ferm::service { 'postgresql':
        proto  => 'tcp',
        port   => 5432,
        srange => '$INTERNAL',
    }

    ganglia::plugin::python { 'diskstat': }
}
