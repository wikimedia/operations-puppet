# == Class: mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
class mediawiki::hhvm {
    requires_ubuntu('>= trusty')

    class { '::hhvm':
        user          => 'apache',
        group         => 'apache',
        fcgi_settings => {
            hhvm => { server => { source_root => '/usr/local/apache/common/docroot' } },
        },
    }

    alternatives::config { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }
}
