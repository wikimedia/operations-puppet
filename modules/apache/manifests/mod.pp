# == Class: apache::mod
#
# This module contains unparametrized classes that wrap some popular
# Apache mods. Because the classes are not parametrized, they may be
# included multiple times without causing duplicate definition errors.
#
class apache::mod {}  # Stub to work around Puppet 2.x parser bug.

# Modules that are bundled with the apache2 package
class apache::mod::actions         { apache::mod_conf { 'actions':        } }
class apache::mod::alias           { apache::mod_conf { 'alias':          } }
class apache::mod::auth_basic      { apache::mod_conf { 'auth_basic':     } }
class apache::mod::authn_file      { apache::mod_conf { 'authn_file':     } }
class apache::mod::authnz_ldap     { apache::mod_conf { 'authnz_ldap':    } }
class apache::mod::authz_user      { apache::mod_conf { 'authz_user':     } }
class apache::mod::cgi             { apache::mod_conf { 'cgi':            } }
class apache::mod::dav             { apache::mod_conf { 'dav':            } }
class apache::mod::dav_fs          { apache::mod_conf { 'dav_fs':         } }
class apache::mod::filter          { apache::mod_conf { 'filter':         } }
class apache::mod::headers         { apache::mod_conf { 'headers':        } }
class apache::mod::proxy           { apache::mod_conf { 'proxy':          } }
class apache::mod::proxy_balancer  { apache::mod_conf { 'proxy_balancer': } }
class apache::mod::proxy_http      { apache::mod_conf { 'proxy_http':     } }
class apache::mod::rewrite         { apache::mod_conf { 'rewrite':        } }
class apache::mod::ssl             { apache::mod_conf { 'ssl':            } }
class apache::mod::userdir         { apache::mod_conf { 'userdir':        } }


# Modules that depend on additional packages
class apache::mod::authz_svn       { apache::mod_conf { 'authz_svn':      } <- package { 'libapache2-svn':           } }
class apache::mod::fastcgi         { apache::mod_conf { 'fastcgi':        } <- package { 'libapache2-mod-fastcgi':   } }
class apache::mod::fcgid           { apache::mod_conf { 'fcgid':          } <- package { 'libapache2-mod-fcgid':     } }
class apache::mod::passenger       { apache::mod_conf { 'passenger':      } <- package { 'libapache2-mod-passenger': } }
class apache::mod::perl            { apache::mod_conf { 'perl':           } <- package { 'libapache2-mod-perl2':     } }
class apache::mod::php5            { apache::mod_conf { 'php5':           } <- package { 'libapache2-mod-php5':      } }
class apache::mod::python          { apache::mod_conf { 'python':         } <- package { 'libapache2-mod-python':    } }
class apache::mod::rpaf            { apache::mod_conf { 'rpaf':           } <- package { 'libapache2-mod-rpaf':      } }
class apache::mod::uwsgi           { apache::mod_conf { 'uwsgi':          } <- package { 'libapache2-mod-uwsgi':     } }
class apache::mod::wsgi            { apache::mod_conf { 'wsgi':           } <- package { 'libapache2-mod-wsgi':      } }

# Modules that target a specific distribution
class apache::mod::proxy_fcgi    { if versioncmp($::lsbdistrelease, '13.10') >= 0 { apache::mod_conf { 'proxy_fcgi':    } } }  # 2.3+
class apache::mod::access_compat { if versioncmp($::lsbdistrelease, '13.10') >= 0 { apache::mod_conf { 'access_compat': } } }  # Not relevant
class apache::mod::version       { if versioncmp($::lsbdistrelease, '13.10')  < 0 { apache::mod_conf { 'version':       } } }  # Baked-in
