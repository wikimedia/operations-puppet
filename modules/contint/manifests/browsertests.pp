# == Class contint::browsertests
class contint::browsertests {

  # Dependencies for qa/browsertests.git
  package { [
    'ruby-bundler',  # installer for qa/browsertests.git
    'rubygems',      # dependency of ruby-bundler
    'ruby1.9',       # state of the art ruby
    'phantomjs',     # headless browser
  ]:
    ensure => present
  }

}
