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

}
