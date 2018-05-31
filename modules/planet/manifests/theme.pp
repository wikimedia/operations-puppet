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
    file { "/var/www/planet/${title}/bootstrap.min.css":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/bootstrap.min.css';
    }
    file { "/var/www/planet/${title}/bootstrap.min.js":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/bootstrap.min.js';
    }
    file { "/var/www/planet/${title}/jquery.min.js":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/jquery.min.js';
    }
    file { "/var/www/planet/${title}/popper.min.js":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/popper.min.js';
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
    file { "/var/www/planet/${title}/fonts":
        ensure  => 'directory',
    }
    file { "/var/www/planet/${title}/fonts/icomoon.eot":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/icomoon.eot';
    }
    file { "/var/www/planet/${title}/fonts/icomoon.svg":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/icomoon.svg';
    }
    file { "/var/www/planet/${title}/fonts/icomoon.ttf":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/icomoon.ttf';
    }
    file { "/var/www/planet/${title}/fonts/icomoon.woff":
        ensure => 'present',
        source => 'puppet:///modules/planet/theme/rawdog/icomoon.woff';
    }
}
