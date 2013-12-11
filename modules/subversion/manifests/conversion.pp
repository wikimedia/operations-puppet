class subversion::conversion {

    package { [
        'libqt4-dev',
        'libsvn-dev',
        'g++',
        ]:
        ensure => present,
    }

}
