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
                    'perf-tools',
                    ]
    require_package($common_pkgs)

    if os_version('ubuntu == trusty') {
        $trusty_pkgs = [
                        'libboost1.54-dbg',
                        'libjson-c2-dbg',
                        'libssl1.0.0-dbg',
                        'libstdc++6-4.8-dbg',
                        'perf-tools',
                        ]

        require_package($trusty_pkgs)
    }

    if os_version('debian == jessie') {
        $jessie_pkgs = [
                        'libboost1.55-dbg',
                        'libjson-c2-dbg',
                        'libssl1.0.0-dbg',
                        'libstdc++6-4.8-dbg',
                        'perf-tools-unstable',
                        ]

        require_package($jessie_pkgs)
    }

    if os_version('debian == stretch') {
        # TODO: libjson-c3-dbgsym, libssl1.0.2-dbgsym
        # Blocked by T164819

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


    ## Misc

    if os_version('ubuntu == trusty') {
        # Backported fix for pretty-printer bundled with libstdc++6-4.8-dbg.
        # See <https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58962> and
        # <https://bugs.launchpad.net/ubuntu/+source/gcc-4.8/+bug/1256419>.

        file { '/usr/share/gcc-4.8/python/libstdcxx/v6/printers.py':
            source  => 'puppet:///modules/hhvm/debug/printers.py',
            require => Package['libstdc++6-4.8-dbg'],
        }
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
