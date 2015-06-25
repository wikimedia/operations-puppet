# == Class contint::browsertests
#
class contint::browsertests {

    # Ship several packages such as php5-sqlite or ruby1.9.3
    include contint::packages

    # Provides phantomjs, firefox and xvfb
    include contint::browsers

    package { [
        'ruby1.9.1-dev', # for qa/browsertests.git (bundler compiles gems)
    ]:
        ensure => present
    }

    # Ruby gems is provided within ruby since Trusty
    if os_version('ubuntu < trusty') {
        package { 'rubygems':
            ensure => present,
        }
    }

    # Ubuntu Precise version is too old.  Instead use either:
    # /srv/deployment/integration/slave-scripts/tools/bundler/bundle
    # or:
    # gem1.9.3 install bundle
    #
    # See JJB configuration files.
    package { [
        'ruby-bundler',
    ]:
        ensure => absent
    }
}
