class role::analytics::research {

    system::role { 'role::analytics::research': description => 'analytics server for research work' }

    # these packages are needed by researchers (halfak)
    # to compile python's numpy and scipy libraries
    package { 'gfortran':
        ensure => 'installed',
    }

    package { 'liblapack-dev':
        ensure => 'installed',
    }

    package { 'libopenblas-dev':
        ensure => 'installed',
    }

}

