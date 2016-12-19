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
            'firefox-esr',
            # phantomjs is not available on Jessie
        ]
        file { '/usr/local/bin/chromedriver':
          ensure => link,
          target => '/usr/lib/chromium/chromedriver',
        }
        package { 'chromium':
            ensure => '53.0.2785',
        }
        package { 'chromedriver':
            ensure => '53.0.2785',
        }
    } elsif os_version('ubuntu >= trusty') {
        $latest_packages = [
            'firefox',
            'phantomjs',
        ]
        file { '/usr/local/bin/chromedriver':
          ensure => link,
          target => '/usr/lib/chromium-browser/chromedriver',
        }
        package { 'chromium-browser':
            ensure => '53.0.2785',
        }
        package { 'chromium-chromedriver':
            ensure => '53.0.2785',
        }
    } else {
        $latest_packages = [
            'firefox',
            'phantomjs',
        ]
        package { 'chromium-browser':
            ensure => '53.0.2785',
        }
    }

    package { $latest_packages:
        ensure => latest,
    }


    class { 'xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
