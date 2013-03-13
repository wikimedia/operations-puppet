# Installs nginx and sets up an NGINX site.
#
#  $install='true' or 'template' causes an nginx config
#  to be installed from either a file or a template, respectively.
#
#  If $install='template' then the config file is pulled from the named
#  template file.  If $install='true' then a config file is pulled
#  from files/nginx/sites/<classname>.
#
#  $enabled='true' adds the site to sites-enabled; $enabled=false removes it.
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
			notify => Service["nginx"];
		}
	} else {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => absent,
			notify => Service["nginx"];
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
