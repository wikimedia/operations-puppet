class contint::browsers {

    package { [
        'phantomjs',
        'firefox',
        'xvfb', # headless testing
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present
    }

    package { 'chromium-browser':
        ensure => latest,
    }

    class { 'xvfb':
        id => 'cibrowser',
        display => 94,
        resolution => '1280x1024x24'
    }
}
