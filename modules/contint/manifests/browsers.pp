class contint::browsers {

    # Without xfonts-cyrillic Xvdb emits warning:
    # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
    require_package('xfonts-cyrillic')

    if $::operatingsystem == 'Debian' {
        # iceweasel rebranded firefox
        require_package('chromium', 'chromedriver', 'iceweasel')
        # phantomjs is not available on Jessie
    } elsif os_version('ubuntu >= trusty') {
        require_package('chromium-browser', 'chromium-chromedriver', 'firefox', 'phantomjs')
    } else {
        require_package('chromium-browser', 'firefox', 'phantomjs')
    }

    class { 'xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
