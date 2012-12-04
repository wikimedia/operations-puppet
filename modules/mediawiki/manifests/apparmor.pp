
class mediawiki::apparmor {

	file {
		'/etc/apparmor.d/usr.bin.avconv':
			owner => root,
			group => root,
			mode => 0644,
			source => 'puppet:///modules/mediawiki_new/apparmor/usr.bin.avconv';
	}
	file {
		'/etc/apparmor.d/usr.bin.ffmpeg2theora':
			owner => root,
			group => root,
			mode => 0644,
			source => 'puppet:///modules/mediawiki_new/apparmor/usr.bin.ffmpeg2theora';
	}
}
