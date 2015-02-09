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

    # Instruct Chromium to route all requests to localhost, and to
    # disable various features that add noise to profiling or that
    # rely on user input.

    class { 'chromium':
        extra_args => [
            '--disable-background-networking',
            '--disable-client-side-phishing-detection',
            '--disable-component-update',
            '--disable-default-apps',
            '--disable-extensions',
            '--disable-hang-monitor',
            '--disable-infobars',
            '--disable-plugins-discovery',
            '--disable-prompt-on-repost',
            '--disable-suggestions-service',
            '--disable-sync',
            '--disable-translate',
            '--disable-v8-idle-tasks',
            '--disable-web-resources',
            '--no-default-browser-check',
            '--no-first-run',
            '--host-rules="MAP * localhost, EXCLUDE upload.wikimedia.org"',
            '--safebrowsing-disable-auto-update',
            '--safebrowsing-disable-download-protection',
        ],
    }

    sudo::group { 'wikidev':
        privileges => [
            'ALL = (root) NOPASSWD: /sbin/restart hhvm',
            'ALL = (root) NOPASSWD: /sbin/start hhvm',
            'ALL = (root) NOPASSWD: /sbin/restart chromium',
            'ALL = (root) NOPASSWD: /sbin/start chromium',
            'ALL = (root) NOPASSWD: /sbin/restart xvfb',
            'ALL = (root) NOPASSWD: /sbin/start xvfb',
        ],
    }


    # vbench is a CLI tool for benchmarking VisualEditor.
    # It uses `autobahn` and `twisted` for WebSocket support, which
    # it needs so it can speak Chrome's remote debugging protocol.
    # It uses `numpy` to calculate summary statistics.

    require_package('python-autobahn', 'python-twisted', 'python-numpy')

    file { '/usr/local/bin/vbench':
        source => 'puppet:///files/ve/vbench',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
