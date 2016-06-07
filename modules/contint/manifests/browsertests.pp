# == Class contint::browsertests
#
class contint::browsertests {

    # Ship several packages such as php5-sqlite or ruby1.9.3
    include contint::packages
    include contint::packages::ruby

    # Provides phantomjs, firefox and xvfb
    include contint::browsers

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
    }

}
