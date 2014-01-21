# defined type: index.html and css theme for a planet-venus language
define planet::theme {

    # file permission defaults
    File {
        owner => 'planet',
        group => 'planet',
        mode  => '0644',
    }

    # so far just one logo for all languages
    $logo = 'planet-wm2.png'

    # use different CSS for Arabic (right-to-left)
    $css_file = $title ? {
        'ar'    => 'planet-ar.css',
        default => 'planet.css',
    }

    # theme directory
    file { "/usr/share/planet-venus/theme/wikimedia/${title}":
        ensure  => directory;
    }
    # index.html template
    file { "/usr/share/planet-venus/theme/wikimedia/${title}/index.html.tmpl":
        ensure  => present,
        content => template('planet/html/index.html.tmpl.erb');
    }
    # theme config file
    file { "/usr/share/planet-venus/theme/wikimedia/${title}/config.ini":
        source  => 'puppet:///modules/planet/theme/config.ini';
    }
    # logo image
    file { "/usr/share/planet-venus/theme/common/images/${logo}":
        source  => "puppet:///modules/planet/theme/images/${logo}";
    }
    # style sheet
    file { "/usr/share/planet-venus/theme/wikimedia/${title}/${css_file}":
        source  => "puppet:///modules/planet/theme/${css_file}";
    }

}
