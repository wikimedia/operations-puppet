# Enables an NGINX site.
#
#
define nginx($install="false", $template="", $enable="true") {
	if !defined (Package["nginx"]) {
		package { ['nginx']:
			ensure => latest;
		}
	}

	if ( $template == "" ) {
		$template_name = $name
	} else {
		$template_name = $template
	}
	if ( $enable == "true" ) {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => "/etc/nginx/sites-available/${name}",
		}
	} else {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => absent;
		}
	}

	case $install {
	"true": {
			file { "/etc/nginx/sites-available/${name}":
				source => "puppet:///files/nginx/sites/${name}";
			}
		}
	"template": {
			file { "/etc/nginx/sites-available/${name}":
				content => template("nginx/sites/${template_name}.erb");
			}
		}
	}

	if !defined (Service["nginx"]) {
        	service { ['nginx']:
			require => Package["nginx"],
                	enable => true,
                	ensure => running;
        	}
	}
}
