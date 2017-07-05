class contint::packages::r {
    packages { [
        'r-base',
        'r-base-dev',
        'libcurl4-openssl-dev',
        'libssh-dev',
        'libssl-dev',
        ]:
            ensure => present,
    }
}
