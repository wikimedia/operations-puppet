class contint::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    if $::operatingsystem == 'Debian' {
        apt::source { 'Debian-stretch':
           comment => 'The Debian Repo',
           location => 'http://ftp.de.debian.org/debian',
           release => 'stretch',
           repos => 'main',
           include_src => false,
           include_deb => true
        }
        $latest_packages = [
            'firefox-esr',
            # phantomjs is not available on Jessie
        ]
        file { '/usr/local/bin/chromedriver':
          ensure => link,
          target => '/usr/lib/chromium/chromedriver',
        }

        package {'chromium':
          ensure => latest,
          require => Apt::Source['Debian-stretch'],
        }
        package {'chromedriver':
          ensure => latest,
          require => Apt::Source['Debian-stretch'],
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
