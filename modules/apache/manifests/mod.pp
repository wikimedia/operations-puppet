# == Class: apache::mod
#
# This module contains unparametrized classes that wrap some popular
# Apache mods. Because the classes are not parametrized, they may be
# included multiple times without causing duplicate definition errors.
#
class apache::mod {}

# Modules that are bundled with the apache2 package
class apache::mod::actions         { mod_conf { 'actions':        } }
class apache::mod::alias           { mod_conf { 'alias':          } }
class apache::mod::auth_basic      { mod_conf { 'auth_basic':     } }
class apache::mod::authn_file      { mod_conf { 'authn_file':     } }
class apache::mod::authz_host      { mod_conf { 'authz_host':     } }
class apache::mod::authnz_ldap     { mod_conf { 'authnz_ldap':    } }
class apache::mod::authz_user      { mod_conf { 'authz_user':     } }
class apache::mod::autoindex       { mod_conf { 'autoindex':      } }
class apache::mod::cgi             { mod_conf { 'cgi':            } }
class apache::mod::dav             { mod_conf { 'dav':            } }
class apache::mod::dav_fs          { mod_conf { 'dav_fs':         } }
class apache::mod::dir             { mod_conf { 'dir':            } }
class apache::mod::env             { mod_conf { 'env':            } }
class apache::mod::expires         { mod_conf { 'expires':        } }
class apache::mod::filter          { mod_conf { 'filter':         } }
class apache::mod::headers         { mod_conf { 'headers':        } }
class apache::mod::mime            { mod_conf { 'mime':           } }
class apache::mod::negotiation     { mod_conf { 'negotiation':    } }
class apache::mod::proxy           { mod_conf { 'proxy':          } }
class apache::mod::proxy_balancer  { mod_conf { 'proxy_balancer': } }
class apache::mod::proxy_http      { mod_conf { 'proxy_http':     } }
class apache::mod::rewrite         { mod_conf { 'rewrite':        } }
class apache::mod::setenvif        { mod_conf { 'setenvif':       } }
class apache::mod::ssl             { mod_conf { 'ssl':            } }
class apache::mod::status          { mod_conf { 'status':         } }
class apache::mod::userdir         { mod_conf { 'userdir':        } }

# Modules that depend on additional packages
class apache::mod::authz_svn       { mod_conf { 'authz_svn':      } <- package { 'libapache2-svn':           } }
class apache::mod::fastcgi         { mod_conf { 'fastcgi':        } <- package { 'libapache2-mod-fastcgi':   } }
class apache::mod::fcgid           { mod_conf { 'fcgid':          } <- package { 'libapache2-mod-fcgid':     } }
class apache::mod::passenger       { mod_conf { 'passenger':      } <- package { 'libapache2-mod-passenger': } }
class apache::mod::perl            { mod_conf { 'perl':           } <- package { 'libapache2-mod-perl2':     } }
class apache::mod::php5            { mod_conf { 'php5':           } <- package { 'libapache2-mod-php5':      } }
class apache::mod::python          { mod_conf { 'python':         } <- package { 'libapache2-mod-python':    } }
class apache::mod::rpaf            { mod_conf { 'rpaf':           } <- package { 'libapache2-mod-rpaf':      } }
class apache::mod::uwsgi           { mod_conf { 'uwsgi':          } <- package { 'libapache2-mod-uwsgi':     } }
class apache::mod::wsgi            { mod_conf { 'wsgi':           } <- package { 'libapache2-mod-wsgi':      } }

# Modules that target a specific distribution
$has_apache_24 = ubuntu_version('>= trusty')

class apache::mod::proxy_fcgi    { if $has_apache_24  { mod_conf { 'proxy_fcgi':    } } }  # 2.3+
class apache::mod::access_compat { if $has_apache_24  { mod_conf { 'access_compat': } } }  # Not relevant
class apache::mod::version       { if !$has_apache_24 { mod_conf { 'version':       } } }  # Baked-in
