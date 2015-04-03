class contint::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    if os_version( 'debian >= jessie' ) {
        # Debian
        package { 'chromium':
            ensure => latest,
        }
        package { 'iceweasel':  # rebranded firefox
            ensure => present,
        }
        # phantomjs is not available on Jessie
    } else {
        # Ubuntu
        package { 'chromium-browser':
            ensure => latest,
        }
        package { [
            'firefox',
            'phantomjs',
        ]:
            ensure => present,
        }
    }

    class { 'xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
