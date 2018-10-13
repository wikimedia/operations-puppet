# defined type: index.html and css theme for a planet language
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

    file { "/etc/rawdog/theme/wikimedia/${title}":
        ensure  => 'directory',
    }
    file { "/var/www/planet/${title}/main.css":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/rawdog_style.css';
    }
    file { "/var/www/planet/${title}/bulma.min.css":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/bulma.min.css';
    }
    file { "/var/www/planet/${title}/Wikimedia_Community_Logo.svg":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/Wikimedia_Community_Logo.svg';
    }
    file { "/etc/rawdog/theme/wikimedia/${title}/rd_page.tmpl":
        ensure  => 'present',
        content => template('planet/html/rawdog/rd_page.html.tmpl.erb');
    }
    file { "/etc/rawdog/theme/wikimedia/${title}/rd_item.tmpl":
        ensure  => 'present',
        content => template('planet/html/rawdog/rd_item.html.tmpl.erb');
    }
}
