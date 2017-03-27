class contint::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    if $::operatingsystem == 'Debian' {
        if os_version( 'debian == jessie' ) {
            apt::pin { 'phantomjs':
                pin      => 'release a=jessie-backports',
                priority => '1001',
            }
        }
        $latest_packages = [
            'chromium',
            'chromedriver',
            'firefox-esr',
            'phantomjs',
        ]
        file { '/usr/local/bin/chromedriver':
          ensure => link,
          target => '/usr/lib/chromium/chromedriver',
        }
    } elsif os_version('ubuntu >= trusty') {
        $latest_packages = [
            'chromium-browser',
            'chromium-chromedriver',
            'firefox',
            'phantomjs',
        ]
        file { '/usr/local/bin/chromedriver':
          ensure => link,
          target => '/usr/lib/chromium-browser/chromedriver',
        }
    }

    package { $latest_packages:
        ensure => latest,
    }


    class { '::xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
