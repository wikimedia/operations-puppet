# == Class: hhvm::dev
#
# Builds Wikimedia's fork of HHVM, for testing HHVM in production.
#
class hhvm::dev {
    $build_deps = [
        'autoconf', 'automake', 'binutils-dev', 'build-essential', 'cmake',
        'g++', 'git', 'libboost-dev', 'libboost-filesystem-dev',
        'libboost-program-options-dev', 'libboost-regex-dev',
        'libboost-system-dev', 'libboost-thread-dev', 'libbz2-dev',
        'libc-client-dev', 'libc-client2007e-dev', 'libcap-dev',
        'libcurl4-openssl-dev', 'libdwarf-dev', 'libelf-dev', 'libexpat-dev',
        'libgd2-xpm-dev', 'libgoogle-glog-dev', 'libgoogle-perftools-dev',
        'libicu-dev', 'libjemalloc-dev', 'libmcrypt-dev', 'libmemcached-dev',
        'libmysqlclient-dev', 'libncurses-dev', 'libonig-dev', 'libpcre3-dev',
        'libreadline-dev', 'libtbb-dev', 'libtool', 'libxml2-dev', 'zlib1g-dev',
        'libevent-dev', 'libmagickwand-dev', 'libinotifytools0-dev',
        'libiconv-hook-dev', 'libedit-dev', 'libiberty-dev', 'libxslt1-dev',
        'ocaml-native-compilers'
    ]

    package { $build_deps:
        ensure => present,
        before => Git::Clone['operations/software/hhvm-dev'],
    }

    git::clone { 'operations/software/hhvm-dev':
        directory          => '/srv/hhvm-dev',
        branch             => 'master',
        owner              => 'mwdeploy',
        group              => 'mwdeploy',
        recurse_submodules => true,
    }

    git::clone { 'mediawiki/php/luasandbox':
        directory          => '/srv/luasandbox',
        branch             => 'master',
        owner              => 'mwdeploy',
        group              => 'mwdeploy',
        recurse_submodules => true,
    }

    git clone:: { 'mediawiki/php/FastStringSearch':
        directory          => '/srv/luasandbox',
        branch             => 'master',
        owner              => 'mwdeploy',
        group              => 'mwdeploy',
        recurse_submodules => true,
    }
}
