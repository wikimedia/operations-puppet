class contint::packages::rlang {
    packages { [
        'libcurl4-openssl-dev',
        'libicu-dev',
        'libssh2-1-dev',
        'libssl-dev',
        'libxml2-dev',
        'r-base',
        'r-base-dev',
        ]:
            ensure => present,
    }
}
