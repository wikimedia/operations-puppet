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
        'ruby1.9.3',     # state of the art ruby
        'phantomjs',     # headless browser
    ]:
        ensure => present
    }

    # Set up all packages required for MediaWiki (includes Apache)
    include mediawiki::packages::math

    package { [
        'chromium-browser',
        'firefox',
        'xvfb',  # headless testing
        'wikimedia-task-appserver',
        'php5-sqlite',  # MediaWiki DB backend
        'libsikuli-script-java',  # bug 54393
        ]: ensure => present
    }

    # And we need a vhost :-)
    contint::localvhost { 'browsertests':
        port       => 9413,
        docroot    => $docroot,
        log_prefix => 'browsertests',
        require    => Package['wikimedia-task-appserver'],
    }

}
