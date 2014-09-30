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

    # Ship several packages such as php5-sqlite or ruby1.9.3
    include contint::packages

    # Provides phantomjs, firefox and xvfb
    include contint::browsers

    package { [
        'ruby1.9.1-dev', # for qa/browsertests.git (bundler compiles gems)
        'libsikuli-script-java', # bug 54393 (for MediaWiki/apache)
    ]:
        ensure => present
    }

    # Ruby gems is provided within ruby since Trusty
    if ubuntu_version('< trusty') {
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

    include ::apache::mod::rewrite

    # And we need a vhost :-)
    contint::localvhost { 'browsertests':
        port       => 9413,
        docroot    => $docroot,
        log_prefix => 'browsertests',
    }

}
