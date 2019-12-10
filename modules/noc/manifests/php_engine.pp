# === Class noc::php_engine
# Configures httpd to serve requests via PHP7 other FastCGI backend
class noc::php_engine($catchall_ensure=present) {

    httpd::mod_conf { 'proxy_fcgi':
        ensure => present,
    }

    httpd::mod_conf { 'mod_php5':
        ensure => absent,
    }

    httpd::conf { 'php_catchall':
        ensure   => $catchall_ensure,
        source   => 'puppet:///modules/mediawiki/apache/configs/php_catchall.conf',
        priority => 50,
    }

    # Add headers lost by mod_proxy_fastcgi
    httpd::conf { 'fcgi_headers':
        source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
        priority => 0,
    }
}
