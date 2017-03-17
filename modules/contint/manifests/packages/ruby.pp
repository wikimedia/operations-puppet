# === Class contint::packages::ruby
#
# This class sets up packages needed for general ruby testing
#
class contint::packages::ruby {

    require_package(
        'build-essential',
    )

    package { 'rubygems-integration':
        ensure => present,
    }
    package { 'rake':
        ensure => present,
    }

    if os_version('ubuntu >= trusty') {
        # ruby defaults to 1.9.3 we want 2.0
        package { [
            'ruby2.0',
            'ruby2.0-dev',
            'ruby-bundler',
            ]: ensure => present,
        }
    }
    if os_version('debian >= jessie') {
        package { [
            'ruby2.1',
            'ruby2.1-dev',
            'bundler',
            # Used by PoolCounter tests (T152338)
            'ruby-rspec',
            'cucumber',
            ]: ensure => present,
        }
    }

    # JSDuck was built for Ubuntu ( T48236/ T82278 )
    # It is a pain to rebuild for Jessie so give up (T95008), we will use
    # bundler/rubygems instead
    if $::operatingsystem == 'Ubuntu' {
        package { 'ruby-jsduck':
            ensure => present,
        }
    }

}
