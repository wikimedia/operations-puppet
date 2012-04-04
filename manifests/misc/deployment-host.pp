# misc/deployment-host.pp

# deployment hosts

class misc::deployment-host {
	system_role { "misc::deployment-host": description => "Deployment" }

	file { "/h"       : ensure => link, target =>  "/home" }
	file { "/home/b"  : ensure => link, target =>  "bin" }
	file { "/home/c"  : ensure => link, target =>  "common" }
	file { "/home/d"  : ensure => link, target =>  "doc" }
	file { "/home/docs": ensure => link, target =>  "doc" }
	file { "/home/h"  : ensure => link, target =>  "htdocs" }
	file { "/home/l"  : ensure => link, target =>  "logs" }
	file { "/home/log": ensure => link, target =>  "logs" }
	file { "/home/s"  : ensure => link, target =>  "src" }
	file { "/home/w"  : ensure => link, target =>  "wikipedia" }

}

