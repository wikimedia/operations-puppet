# == Class contint::browsertests
#
# == Parameters:
#
# *docroot*  Where the virtualhost will be pointing to. Default to
# /srv/localhost/browsertests which is suitable for future production purposes.
#
class contint::browsertests(
  $docroot = '/srv/localhost/browsertests',
){

  # Dependencies for qa/browsertests.git
  package { [
    'ruby-bundler',  # installer for qa/browsertests.git
    'rubygems',      # dependency of ruby-bundler
    'ruby1.9',       # state of the art ruby
    'phantomjs',     # headless browser
  ]:
    ensure => present
  }

  # And we need a vhost :-)
  contint::localvhost { 'browsertests':
    port       => 9413,
    docroot    => $docroot,
    log_prefix => 'browsertests',
  }

}
