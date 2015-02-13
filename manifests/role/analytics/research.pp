class role::analytics::research {

    system::role { 'role::analytics::research': description => 'analytics server for research work' }

    # these packages are needed by researchers (halfak)
    # to compile python's numpy and scipy libraries

    # GNU Fortran 95 compiler
    package { 'gfortran':
        ensure => 'installed',
    }

    # FORTRAN library of linear algebra routines
    package { 'liblapack-dev':
        ensure => 'installed',
    }

    # Optimized BLAS (linear algebra) library
    package { 'libopenblas-dev':
        ensure => 'installed',
    }

}

