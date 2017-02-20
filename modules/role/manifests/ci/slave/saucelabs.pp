# == Class role::ci::slave::saucelabs
#
# Configure an instance to be used as a runner for the mediawiki_selenium daily
# jobs which rely on SauceLabs.
#
# That kind of slave does not need a local Xvfb nor any browser or Apache
# configuration since everything is handled on Saucelabs or the target website.
#
# filtertags: labs-project-git labs-project-integration labs-project-ci-staging
class role::ci::slave::saucelabs {

    system::role { 'role::ci::slave::saucelabs':
        description => 'CI Jenkins slave for jobs running on SauceLabs',
    }

    include ::role::ci::slave::labs::common

    include ::contint::packages::ruby
    include ::contint::slave_scripts
}
