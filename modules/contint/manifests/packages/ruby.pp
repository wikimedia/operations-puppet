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

    package { [
        'ruby2.1',
        'ruby2.1-dev',
        'bundler',
        # Used by PoolCounter tests (T152338)
        'ruby-rspec',
        'cucumber',
        ]: ensure => present,
    }

    # JSDuck was built for Ubuntu ( T48236/ T82278 )
    # It is a pain to rebuild for Jessie so give up (T95008), we will use
    # bundler/rubygems instead
    package { 'jsduck':
        ensure   => present,
        provider => 'gem',
        require  => [
            Package['ruby2.1-dev'],
            Package['build-essential'],
        ],
    }

}
