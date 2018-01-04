# defined type: index.html and css theme for a planet-venus or rawdog language
define planet_httpd::theme {

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
        file { "/etc/rawdog/theme/wikimedia/${title}":
            ensure  => 'directory',
        }
        file { "/var/www/planet/${title}/style.css":
            ensure => 'present',
            source => 'puppet:///modules/planet/theme/rawdog_style.css';
        }
        file { "/var/www/planet/${title}/Wikimedia_Community_Logo.svg":
            ensure => 'present',
            source => 'puppet:///modules/planet/theme/Wikimedia_Community_Logo.svg';
        }
        file { "/etc/rawdog/theme/wikimedia/${title}/rd_page.tmpl":
            ensure  => 'present',
            content => template('planet/html/rd_page.html.tmpl.erb');
        }
        file { "/etc/rawdog/theme/wikimedia/${title}/rd_item.tmpl":
            ensure  => 'present',
            content => template('planet/html/rd_item.html.tmpl.erb');
        }
    } else {
        $theme_path = '/usr/share/planet-venus/theme/wikimedia'
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
}
