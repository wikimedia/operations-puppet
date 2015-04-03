class contint::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    if os_version( 'debian >= lenny' ) {
        # Debian
        $latest_packages = [
            'chromium',
            'iceweasel',  # rebranded firefox
            # phantomjs is not available on Jessie
        ]
    } else {
        # Ubuntu
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
