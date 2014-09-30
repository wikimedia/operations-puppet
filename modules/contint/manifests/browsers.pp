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

    file { '/etc/init/xvfb-cibrowser.conf':
        content => template('contint/xvfb-cibrowser.upstart.conf'),
        require => [ Package['xvfb'] ],
    }

    service { 'xvfb':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/xvfb-cibrowser.conf'],
    }
}
