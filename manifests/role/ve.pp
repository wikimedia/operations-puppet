# == Class: role::ve
#
# Sets up a Visual Editor performance testing rig with a headless
# Chromium instance that supports remote debugging.
#
class role::ve {
    include ::mediawiki
    include ::mediawiki::web
    include ::mediawiki::web::sites

    # 1366x768 is the most common display resolution, according
    # to http://gs.statcounter.com/.

    class { 'xvfb':
        resolution => '1366x768x24',
    }

    # Instruct Chromium to route all requests to localhost.

    class { 'chromium':
        extra_args => '--proxy-server=http://127.0.0.1',
    }

    # vbench is a CLI tool for benchmarking VisualEditor.
    # It uses `autobahn` and `twisted` for WebSocket support, which
    # it needs so it can speak Chrome's remote debugging protocol.

    require_package('python-autobahn', 'python-twisted', 'python-numpy')

    file { '/usr/local/bin/vbench':
        source => 'puppet:///files/ve/vbench',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
