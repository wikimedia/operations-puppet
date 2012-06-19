# misc/deployment-host.pp

# deployment hosts

class misc::deployment-host {
	system_role { "misc::deployment-host": description => "Deployment" }

	$wp = '/home/wikipedia'

	file {
		"/h"         : ensure => link, target =>  "/home";
		"/home/w"    : ensure => link, target =>  '/home/wikipedia';

		"${wp}/b"   : ensure => link, target =>  "${wp}/bin";
		"${wp}/c"   : ensure => link, target =>  "${wp}/common";
		"${wp}/d"   : ensure => link, target =>  "${wp}/doc";
		"${wp}/docs": ensure => link, target =>  "${wp}/doc";
		"${wp}/h"   : ensure => link, target =>  "${wp}/htdocs";
		"${wp}/l"   : ensure => link, target =>  "${wp}/logs";
		"${wp}/log" : ensure => link, target =>  "${wp}/logs";
		"${wp}/s"   : ensure => link, target =>  "${wp}/src";
	}
}

