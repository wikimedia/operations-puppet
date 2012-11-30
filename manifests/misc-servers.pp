# misc-servers.pp

# Resource definitions for miscellaneous servers

import "generic-definitions.pp"
import "nagios.pp"

class misc::images::rsyncd {
	system_role { "misc::images::rsyncd": description => "images rsync daemon" }

	class { 'generic::rsyncd': config => "export" }
}

class misc::images::rsync {
	system_role { "misc::images::rsync": description => "images rsync mirror host" }

	require misc::images::rsyncd

	$rsync_includes = "
- /upload/centralnotice/
- /upload/ext-dist/
+ /upload/wik*/
+ /private/
- **/thumb/
"

	file { "/etc/rsync.includes":
		content => $rsync_includes;
	}

	upstart_job { "rsync-images": install => "true" }
}

