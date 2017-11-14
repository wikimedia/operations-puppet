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

    if os_version('debian == stretch') {
      $ruby_version = '2.3'
    } else {
      $ruby_version = '2.1'
    }

    package { [
        "ruby${ruby_version}",
        "ruby${ruby_version}-dev",
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
            Package["ruby${ruby_dev_version}-dev"],
            Package['build-essential'],
        ],
    }
}
