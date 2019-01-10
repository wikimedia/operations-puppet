# == Class: hhvm::debug
#
# Debugging symbols and tools for HHVM and related software.
#
class hhvm::debug {

    # This class installs packages with debugging symbols and a number
    # of tools:

    # - google-perftools includes `pprof` (aliased as `google-pprof`),
    #   which can generate useful reports from jemalloc heap dumps.
    # - perf-tools is <https://github.com/brendangregg/perf-tools>.
    # - The gv and graphiz packages enable pprof to generate PDF and SVG
    #   reports of things like call graphs.
    # - apache2-utils provides `ab`, an HTTP server benchmarking tool.

    $common_pkgs = [
                    'apache2-utils',
                    'google-perftools',
                    'graphviz',
                    'gv',
                    'hhvm-dbg',
                    'libc6-dbg',
                    'libcurl3-dbg',
                    'libevent-dbg',
                    'libgcc1-dbg',
                    'libjemalloc1-dbg',
                    'libldap-2.4-2-dbg',
                    'libmemcached-dbg',
                    'libpcre3-dbg',
                    'libsqlite3-0-dbg',
                    'libxml2-dbg',
                    'libxslt1-dbg',
                    ]
    require_package($common_pkgs)

    if os_version('debian == stretch') {
        # TODO: libjson-c3-dbgsym, libssl1.0.2-dbgsym, libboost-atomic1.62.0-dbgsym
        # libboost-chrono1.62.0-dbgsym, libboost-context1.62.0-dbgsym
        # libboost-coroutine1.62.0-dbgsym, libboost-date-time1.62.0-dbgsym
        # libboost-fiber1.62.0-dbgsym, libboost-filesystem1.62.0-dbgsym
        # libboost-graph-parallel1.62.0-dbgsym, libboost-graph1.62.0-dbgsym
        # libboost-iostreams1.62.0-dbgsym, libboost-locale1.62.0-dbgsym
        # libboost-log1.62.0-dbgsym, libboost-math1.62.0-dbgsym
        # libboost-mpi-python1.62.0-dbgsym, libboost-mpi1.62.0-dbgsym
        # libboost-program-options1.62.0-dbgsym, libboost-python1.62.0-dbgsym
        # libboost-random1.62.0-dbgsym, libboost-regex1.62.0-dbgsym
        # libboost-serialization1.62.0-dbgsym, libboost-signals1.62.0-dbgsym
        # libboost-system1.62.0-dbgsym, libboost-test1.62.0-dbgsym
        # libboost-thread1.62.0-dbgsym, libboost-timer1.62.0-dbgsym
        # libboost-type-erasure1.62.0-dbgsym,libboost-wave1.62.0-dbgsym
        # libboost1.62-tools-dev-dbgsym
        # -> All blocked by T164819
        $stretch_pkgs = [
                        'libstdc++6-6-dbg',
                        'perf-tools-unstable',
                        ]

        require_package($stretch_pkgs)
    }

    # `hhvm-dump-debug` dumps an HHVM backtrace to /tmp.
    # When invoked with "--full", also dumps core.

    file { '/usr/local/sbin/hhvm-dump-debug':
        source => 'puppet:///modules/hhvm/debug/hhvm-dump-debug',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # `hhvmadm` is a shell helper for cURLing endpoints of the HHVM
    # admin server.
    #
    # Usage:
    #  hhvmadm [ENDPOINT] [--KEY=VALUE ..]
    #
    # Example:
    #  hhvmadm jemalloc-dump-prof --file=/tmp/dump.heap
    #
    # Invoke `hhvmadm` with no arguments to see a list of endpoints.

    file { '/usr/local/bin/hhvmadm':
        source => 'puppet:///modules/hhvm/debug/hhvmadm',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }


    ## Source code

    # Install HHVM's source files to /usr/src/hhvm.

    package { 'dpkg-dev':
        ensure => present,
    }

    file { '/usr/local/sbin/install-pkg-src':
        source => 'puppet:///modules/hhvm/debug/install-pkg-src',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    exec { '/usr/local/sbin/install-pkg-src hhvm':
        unless  => '/usr/local/sbin/install-pkg-src --dry-run hhvm | grep -q up-to-date',
        require => Package['dpkg-dev', 'hhvm'],
    }


    ## Memory leaks

    # We provision two scripts that help isolate memory leaks.
    # First, run `hhvm-collect-heaps` to enable jemalloc heap
    # profiling and to write a heap dump for HHVM to /tmp/heaps
    # once every ten minutes. Once you have several heaps, run
    # `hhvm-diff-heaps` to subtract each heap from its successor
    # and reveal where memory is being allocated.
    #
    # See T820 and T99525 for example investigations using this
    # method.

    file { '/usr/local/sbin/hhvm-collect-heaps':
        source => 'puppet:///modules/hhvm/debug/hhvm-collect-heaps',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/hhvm-diff-heaps':
        source => 'puppet:///modules/hhvm/debug/hhvm-diff-heaps',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
