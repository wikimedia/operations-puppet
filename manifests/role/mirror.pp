# role/mirror.pp
# mirror::media and mirror::dumps role classes

class role::mirror::common {

	$cluster = "misc"

	package { rsync:
		ensure => latest;
	}

	include generic::sysctl::high-bandwidth-rsync
}

class role::mirror::media {
	include role::mirror::common

	system_role { "role::mirror::media": description => "Media mirror (rsync access for external mirrors)" }

	file {
		'/root/backups/rsync-media-cron.sh':
			mode => 0755,
			source => "puppet:///files/misc/mirror/rsync-media-cron.sh",
			ensure => present;
	}

	cron {
		'media_rsync':
			user => root,
			minute => '20',
			hour => '3',
			command => '/root/backups/rsync-media-cron.sh',
			environment => 'MAILTO=ops-dumps@wikimedia.org',
			ensure => present;
	}
}

class role::mirror::kiwix {
	include role::mirror::common

        system_role { "role::mirror::kiwix": description => "Kiwix mirror" }

        group { mirror:
                ensure => "present";
        }

        user { mirror:
                name => "mirror",
                gid => "mirror",
                groups => [ "www-data"],
                membership => "minimum",
                home => "/data/home",
                shell => "/bin/bash";
        }

        file {
                "/data/xmldatadumps/public/kiwix":
                        ensure => "/data/xmldatadumps/public/other/kiwix";
                "/data/xmldatadumps/public/other/kiwix":
                        owner => "mirror",
                        group => "mirror",
                        mode => 0644,
                        ensure => present;
        }

        cron { kiwix-mirror-update:
                command => "rsync -vzrlptD  download.kiwix.org::download.kiwix.org/zim/0.9/ /data/xmldatadumps/public/other/kiwix/zim/0.9/ >/dev/null 2>&1",
                user => mirror,
                minute => '*/15',
                require => File[ [ '/data/xmldatadumps/public/kiwix', '/data/xmldatadumps/public/other/kiwix' ] ]
                ensure => present;
        }

}
