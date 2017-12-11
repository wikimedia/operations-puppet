# == Class profile::ci::browsertests
#
class profile::ci::browsertests {

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
    }

}
