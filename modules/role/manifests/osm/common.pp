class role::osm::common {
    include ::standard
    $pgversion = $::lsbdistcodename ? {
        'stretch' => '9.6',
        'jessie'  => '9.4',
    }

    $root_dir = '/srv/postgres'

    file { "/etc/postgresql/${pgversion}/main/tuning.conf":
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/role/osm/tuning.conf',
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }

    ferm::service { 'postgresql_osm':
        proto  => 'tcp',
        port   => 5432,
        srange => '$LABS_NETWORKS',
    }

}
