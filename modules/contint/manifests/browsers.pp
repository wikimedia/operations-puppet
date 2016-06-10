class contint::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    if $::operatingsystem == 'Debian' {
        $latest_packages = [
            'chromium',
            'chromedriver',
            'iceweasel',  # rebranded firefox
            # phantomjs is not available on Jessie
        ]
    } elsif os_version('ubuntu >= trusty') {
        # Chromium on hold T137561
        apt::pin { 'firefox':
            pin      => 'version 46.0.1+build1-0ubuntu0.14.04.3',
            priority => '1001',
        }
        $latest_packages = [
            'chromium-browser',
            'chromium-chromedriver',
            'firefox',
            'phantomjs',
        ]
    } else {
        $latest_packages = [
            'chromium-browser',
            'firefox',
            'phantomjs',
        ]
    }

    package { $latest_packages:
        ensure => latest,
    }


    class { 'xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
