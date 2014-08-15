# == Class: mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
class mediawiki::hhvm {
    requires_ubuntu('>= trusty')

    include ::hhvm::monitoring
    include ::mediawiki::users

    class { '::hhvm':
        user          => 'apache',
        group         => 'apache',
        fcgi_settings => {
            hhvm => {
                server => {
                    source_root => '/usr/local/apache/common/docroot',
                },
            },
        },
    }

    exec { 'set_hhvm_as_default_php':
        command => 'update-alternatives --force --set php /usr/bin/hhvm',
        unless  => '/usr/bin/test "$(/bin/readlink -f /etc/alternatives/php)" = "/usr/bin/hhvm"',
        require => Package['hhvm'],
    }
}
