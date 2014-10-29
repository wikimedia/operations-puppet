# == Class: hhvm::packages
#
# Packages for running and debugging HHVM in production.
#
class hhvm::packages {

    ## Base packages

    package { [
        'hhvm',
        'hhvm-dbg',
    ]:
        ensure => present,
    }


    ## HHVM extensions

    package { [
        'hhvm-fss',
        'hhvm-luasandbox',
        'hhvm-wikidiff2',
    ]:
        ensure => present,
    }


    ## Debug symbols

    package { [
        'libboost1.54-dbg',
        'libc6-dbg',
        'libcurl3-dbg',
        'libevent-dbg',
        'libgcc1-dbg',
        'libjemalloc1-dbg',
        'libjson-c2-dbg',
        'libldap-2.4-2-dbg',
        'libmemcached-dbg',
        'libpcre3-dbg',
        'libsqlite3-0-dbg',
        'libssl1.0.0-dbg',
        'libstdc++6-4.8-dbg',
        'libxml2-dbg',
        'libxslt1-dbg',
    ]:
        ensure => present,
    }


    ## Profiling and debugging tools

    package { [
        'dpkg-dev',
        'google-perftools',
        'graphviz',
        'gv',
    ]:
        ensure => present,
    }
}
