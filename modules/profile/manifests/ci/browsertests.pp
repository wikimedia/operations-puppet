# == Class profile::ci::browsertests
#
class profile::ci::browsertests {

    class { '::contint::packages::ruby':
    }

    # Provides phantomjs, firefox and xvfb
    class { '::contint::browsers':
    }

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
    }

}
