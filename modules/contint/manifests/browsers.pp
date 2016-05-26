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
        ensure => present,  # Chromium on hold T136188
    }


    class { 'xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
