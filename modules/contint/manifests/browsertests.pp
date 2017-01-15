# == Class contint::browsertests
#
class contint::browsertests {

    include ::contint::packages::ruby

    # Provides phantomjs, firefox and xvfb
    include ::contint::browsers

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
    }

}
