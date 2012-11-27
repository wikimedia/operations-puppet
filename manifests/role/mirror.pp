# role/mirror.pp
# mirror::media and mirror::dumps role classes

class role::mirror {

	$cluster = "misc"

	package { rsync:
		ensure => latest;
	}

	class role::mirror::media {
		system_role { "role::mirror::media": description => "Media mirror (rsync access for external mirrors)" }

		include generic::sysctl::high-bandwidth-rsync

		cron {
			'media_rsync':
				user => root,
				minute => '20',
				hour => '3',
				command => '/root/backups/rsync-media-cron.sh',
				environment => 'MAILTO:ops-dumps@wikimedia.org',
				ensure => present,
		}
	}
}
