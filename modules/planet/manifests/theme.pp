# defined type: index.html and css theme for a planet-venus or rawdog language
define planet::theme {

    # file permission defaults
    File {
        owner => 'planet',
        group => 'planet',
        mode  => '0644',
    }

    # use different CSS for Arabic (right-to-left)
    $css_file = $title ? {
        'ar'    => 'planet-ar.css',
        default => 'planet.css',
    }


    if os_version('debian == stretch') {
        $theme_path = '/etc/rawdog/theme/wikimedia'

        file { "/var/www/planet/${title}/style.css":
            ensure  => 'present',
            source  => 'puppet:///modules/planet/theme/rawdog_style.css';
        }
    } else {
        $theme_path = '/usr/share/planet-venus/theme/wikimedia'
    }

    # theme directory
    file { "${theme_path}/${title}":
        ensure  => 'directory',
    }
    # index.html template
    file { "${theme_path}/${title}/index.html.tmpl":
        ensure  => 'present',
        content => template('planet/html/index.html.tmpl.erb');
    }
    # theme config file
    file { "${theme_path}/${title}/config.ini":
        source  => 'puppet:///modules/planet/theme/config.ini';
    }
    # style sheet for planet-venus
    file { "${theme_path}/${title}/planet.css":
        source  => "puppet:///modules/planet/theme/${css_file}";
    }
}
