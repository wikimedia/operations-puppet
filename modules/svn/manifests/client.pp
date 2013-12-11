class svn::client {
    package { 'subversion':
        ensure => latest,
    }
}
