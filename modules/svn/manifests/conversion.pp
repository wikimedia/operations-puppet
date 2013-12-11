class svn::conversion {
    package { ['libqt4-dev',
        'libsvn-dev',
        'g++',]:
        ensure => latest,
    }
}
