# == Class contint::mediawiki_selenium
#
# Base dependencies required for the mediawiki_selenium ruby gem.
class contint::mediawiki_selenium {

    include ::contint::packages::ruby

    # For Selenium jobs recording (T113520)
    package { 'libav-tools':
        ensure => present,
    }

}
