# == Class: apache::mod
#
# This module contains unparametrized classes that wrap some popular
# Apache mods. Because the classes are not parametrized, they may be
# included multiple times without causing duplicate definition errors.
#
class apache::mod {}

# Modules that are bundled with the apache2 package
# lint:ignore:autoloader_layout
# ^ FIXABLE ?

# https://httpd.apache.org/docs/current/mod/mod_access_compat.html
class apache::mod::access_compat   { apache::mod_conf { 'access_compat':  } }

# https://httpd.apache.org/docs/current/mod/mod_actions.html
class apache::mod::actions         { apache::mod_conf { 'actions':        } }

# https://httpd.apache.org/docs/current/mod/mod_alias.html
class apache::mod::alias           { apache::mod_conf { 'alias':          } }

# https://httpd.apache.org/docs/current/mod/mod_auth_basic.html
class apache::mod::auth_basic      { apache::mod_conf { 'auth_basic':     } }

# https://httpd.apache.org/docs/current/mod/mod_authn_file.html
class apache::mod::authn_file      { apache::mod_conf { 'authn_file':     } }

# https://httpd.apache.org/docs/current/mod/mod_authz_groupfile.html
class apache::mod::authz_groupfile { apache::mod_conf { 'authz_groupfile': } }

# https://httpd.apache.org/docs/current/mod/mod_authz_host.html
class apache::mod::authz_host      { apache::mod_conf { 'authz_host':     } }

# https://httpd.apache.org/docs/current/mod/mod_authnz_ldap.html
class apache::mod::authnz_ldap     { apache::mod_conf { 'authnz_ldap':    } }

# https://httpd.apache.org/docs/current/mod/mod_authz_user.html
class apache::mod::authz_user      { apache::mod_conf { 'authz_user':     } }

# https://httpd.apache.org/docs/current/mod/mod_autoindex.html
class apache::mod::autoindex       { apache::mod_conf { 'autoindex':      } }

# https://httpd.apache.org/docs/current/mod/mod_cgi.html
class apache::mod::cgi             { apache::mod_conf { 'cgi':            } }

# https://httpd.apache.org/docs/current/mod/mod_dav.html
class apache::mod::dav             { apache::mod_conf { 'dav':            } }

# https://httpd.apache.org/docs/current/mod/mod_dav_fs.html
class apache::mod::dav_fs          { apache::mod_conf { 'dav_fs':         } }

# https://httpd.apache.org/docs/current/mod/mod_dir.html
class apache::mod::dir             { apache::mod_conf { 'dir':            } }

# https://httpd.apache.org/docs/current/mod/mod_env.html
class apache::mod::env             { apache::mod_conf { 'env':            } }

# https://httpd.apache.org/docs/current/mod/mod_expires.html
class apache::mod::expires         { apache::mod_conf { 'expires':        } }

# https://httpd.apache.org/docs/current/mod/mod_filter.html
class apache::mod::filter          { apache::mod_conf { 'filter':         } }

# https://httpd.apache.org/docs/current/mod/mod_headers.html
class apache::mod::headers         { apache::mod_conf { 'headers':        } }

# https://httpd.apache.org/docs/current/mod/mod_lbmethod_byrequests.html
class apache::mod::lbmethod_byrequests  { apache::mod_conf { 'lbmethod_byrequests': } }

# https://httpd.apache.org/docs/current/mod/mod_mime.html
class apache::mod::mime            { apache::mod_conf { 'mime':           } }

# https://httpd.apache.org/docs/current/mod/mod_negotiation.html
class apache::mod::negotiation     { apache::mod_conf { 'negotiation':    } }

# https://httpd.apache.org/docs/current/mod/mod_proxy.html
class apache::mod::proxy           { apache::mod_conf { 'proxy':          } }

# https://httpd.apache.org/docs/current/mod/mod_proxy_balancer.html
class apache::mod::proxy_balancer  { apache::mod_conf { 'proxy_balancer': } }

# https://httpd.apache.org/docs/current/mod/mod_proxy_fcgi.html
class apache::mod::proxy_fcgi      { apache::mod_conf { 'proxy_fcgi':     } }

# https://httpd.apache.org/docs/current/mod/mod_proxy_html.html
class apache::mod::proxy_html      { apache::mod_conf { 'proxy_html':     } }

# https://httpd.apache.org/docs/current/mod/mod_proxy_http.html
class apache::mod::proxy_http      { apache::mod_conf { 'proxy_http':     } }

# https://httpd.apache.org/docs/current/mod/mod_remoteip.html
class apache::mod::remoteip        { apache::mod_conf { 'remoteip':       } }

# https://httpd.apache.org/docs/current/mod/mod_authz_user.html
class apache::mod::rewrite         { apache::mod_conf { 'rewrite':        } }

# https://httpd.apache.org/docs/current/mod/mod_setenvif.html
class apache::mod::setenvif        { apache::mod_conf { 'setenvif':       } }

# https://httpd.apache.org/docs/current/mod/mod_ssl.html
class apache::mod::ssl             { apache::mod_conf { 'ssl':            } }

# https://httpd.apache.org/docs/current/mod/mod_substitute.html
class apache::mod::substitute      { apache::mod_conf { 'substitute':     } }

# https://httpd.apache.org/docs/current/mod/mod_userdir.html
class apache::mod::userdir         { apache::mod_conf { 'userdir':        } }

# https://httpd.apache.org/docs/current/mod/mod_xml2enc.html
class apache::mod::xml2enc         { apache::mod_conf { 'xml2enc':        } }

# lint:endignore

# Modules that depend on additional packages
# lint:ignore:right_to_left_relationship lint:ignore:autoloader_layout
# FIXABLE ^ ?

# https://httpd.apache.org/docs/current/mod/mod_authz_svn.html
class apache::mod::authz_svn       { apache::mod_conf { 'authz_svn':      } <- package { 'libapache2-svn':           } }

# https://httpd.apache.org/docs/current/mod/mod_fastcgi.html
class apache::mod::fastcgi         { apache::mod_conf { 'fastcgi':        } <- package { 'libapache2-mod-fastcgi':   } }

# https://httpd.apache.org/docs/current/mod/mod_fcgid.html
class apache::mod::fcgid           { apache::mod_conf { 'fcgid':          } <- package { 'libapache2-mod-fcgid':     } }

# https://httpd.apache.org/docs/current/mod/mod_passenger.html
class apache::mod::passenger       { apache::mod_conf { 'passenger':      } <- package { 'libapache2-mod-passenger': } }

# https://httpd.apache.org/docs/current/mod/mod_perl.html
class apache::mod::perl            { apache::mod_conf { 'perl':           } <- package { 'libapache2-mod-perl2':     } }

# https://httpd.apache.org/docs/current/mod/mod_php5.html
class apache::mod::php5            { apache::mod_conf { 'php5':           } <- package { 'libapache2-mod-php5':      } }

# https://httpd.apache.org/docs/current/mod/mod_python.html
class apache::mod::python          { apache::mod_conf { 'python':         } <- package { 'libapache2-mod-python':    } }

# https://httpd.apache.org/docs/current/mod/mod_rpaf.html
class apache::mod::rpaf            { apache::mod_conf { 'rpaf':           } <- package { 'libapache2-mod-rpaf':      } }

# https://httpd.apache.org/docs/current/mod/mod_security2.html
class apache::mod::security2       { apache::mod_conf { 'security2':      } <- package { 'libapache2-mod-security2': } }

# https://httpd.apache.org/docs/current/mod/mod_uwsgi.html
class apache::mod::uwsgi           { apache::mod_conf { 'uwsgi':          } <- package { 'libapache2-mod-uwsgi':     } }

# https://httpd.apache.org/docs/current/mod/mod_wsgi.html
class apache::mod::wsgi            { apache::mod_conf { 'wsgi':           } <- package { 'libapache2-mod-wsgi':      } }

# lint:endignore

# == Class: apache::mod::status
#
# The default mod_status configuration enables /server-status on all
# vhosts for local requests, but it does not correctly distinguish
# between requests which are truly local and requests that have been
# proxied. Because most of our Apaches sit behind a reverse proxy, the
# default configuration is not safe, so we make sure to replace it with
# a more conservative configuration that makes /server-status accessible
# only to requests made via the loopback interface. See T113090.
#
class apache::mod::status { # lint:ignore:autoloader_layout
    file { [
        '/etc/apache2/mods-available/status.conf',
        '/etc/apache2/mods-enabled/status.conf',
    ]:
        ensure  => absent,
        before  => Apache::Mod_conf['status'],
        require => Package['apache2'],
    }

    apache::mod_conf { 'status': }

    apache::conf { 'server_status':
        source  => 'puppet:///modules/apache/status.conf',
        require =>  Apache::Mod_conf['status'],
    }
}
