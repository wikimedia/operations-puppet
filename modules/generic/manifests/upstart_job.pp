# Create a symlink in /etc/init.d/ to a generic upstart init script
define generic::upstart_job($install="false", $start="false") {
	# Create symlink
	file { "/etc/init.d/${title}":
		ensure => "/lib/init/upstart-job";
	}

	if $install == "true" {
		file { "/etc/init/${title}.conf":
			source => "puppet:///modules/generic/upstart/${title}.conf"
		}
	}

	if $start == "true" {
		exec { "start $title":
			require => File["/etc/init/${title}.conf"],
			subscribe => File["/etc/init/${title}.conf"],
			refreshonly => true,
			command => "start ${title}",
			path => "/bin:/sbin:/usr/bin:/usr/sbin"
		}
	}
}
