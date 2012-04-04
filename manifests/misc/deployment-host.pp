# misc/deployment-host.pp

# deployment hosts

class misc::deployment-host {
	system_role { "misc::deployment-host": description => "Deployment" }

	$wp = '/home/wikipedia'

	file { "/h"         : ensure => link, target =>  "/home" }
	file { "/home/w"    : ensure => link, target =>  '/home/wikipedia' }

	file { "{$wp}/b"   : ensure => link, target =>  $wp + "/bin" }
	file { "{$wp}/c"   : ensure => link, target =>  $wp + "/common" }
	file { "{$wp}/d"   : ensure => link, target =>  $wp + "/doc" }
	file { "{$wp}/docs": ensure => link, target =>  $wp + "/doc" }
	file { "{$wp}/h"   : ensure => link, target =>  $wp + "/htdocs" }
	file { "{$wp}/l"   : ensure => link, target =>  $wp + "/logs" }
	file { "{$wp}/log" : ensure => link, target =>  $wp + "/logs" }
	file { "{$wp}/s"   : ensure => link, target =>  $wp + "/src" }

}

