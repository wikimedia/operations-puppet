class profile::ci::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    $latest_packages = [
        'chromium',
        'chromedriver',
        'firefox-esr',
    ]
    file { '/usr/local/bin/chromedriver':
      ensure => link,
      target => '/usr/lib/chromium/chromedriver',
    }

    package { $latest_packages:
        ensure => latest,
    }


    class { '::xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
