# == Class: mediawiki::hhvm
#
# Configures HHVM to serve MediaWiki in FastCGI mode.
#
class mediawiki::hhvm {
    requires_ubuntu('>= trusty')

    include ::hhvm::admin
    include ::hhvm::monitoring
    include ::mediawiki::users


    class { '::hhvm':
        user          => 'apache',
        group         => 'apache',
        fcgi_settings => {
            hhvm => {
                error_handling => {
                    call_user_handler_on_fatals => true,
                },
                server         => {
                    source_root           => '/srv/mediawiki/docroot',
                    error_document500     => '/srv/mediawiki/hhvm-fatal-error.php',
                    error_document404     => '/srv/mediawiki/w/404.php',
                    request_init_document => '/srv/mediawiki/wmf-config/HHVMRequestInit.php',
                },
            },
        },
    }


    # furl is a cURL-like command-line tool for making FastCGI requests.
    # See `furl --help` for documentation and usage.

    file { '/usr/local/bin/furl':
        source  => 'puppet:///modules/mediawiki/furl',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }


    # Use Debian's Alternatives system to mark HHVM as the default PHP
    # implementation for this system. This makes /usr/bin/php a symlink
    # to /usr/bin/hhvm.

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
        before  => Service['hhvm'],
    }
}
