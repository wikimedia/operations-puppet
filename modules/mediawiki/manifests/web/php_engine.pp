# === Class mediawiki::web::php_engine
# Selects to run web requests via mod_php or HHVM depending on the OS version.
class mediawiki::web::php_engine {
    if os_version('ubuntu >= trusty') {
        include ::apache::mod::proxy_fcgi

        apache::mod_conf { 'mod_php5':
            ensure => absent,
        }

        # HHVM catchall, and removal of mod_php
        apache::conf { 'hhvm_catchall':
            source   => 'puppet:///modules/mediawiki/apache/configs/hhvm_catchall.conf',
            priority => 50,
        }

        # Mark static assets as coming from an HHVM appserver as well. Needed for Varnish
        apache::conf { 'mark_engine':
            source   => 'puppet:///modules/mediawiki/apache/configs/hhvm_mark_engine.conf',
            priority => 49,
        }

        # Add headers lost by mod_proxy_fastcgi
        apache::conf { 'fcgi_headers':
            source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
            priority => 0,
        }


    } else {
        include ::apache::mod::php5
    }

}
