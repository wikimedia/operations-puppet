# imagescaler.pp

# Virtual resource for the monitoring server
@monitor_group { "image_scalers": description => "image scalers" }

class imagescaler::cron {
	cron { removetmpfiles:
		command => "for dir in /tmp /a/magick-tmp; do find \$dir -type f \\( -name 'gs_*' -o -name 'magick-*' \\) -cmin +15 -exec rm -f {} \\;; done",
		user => root,
		minute => '*/5',
		ensure => present
	}
}

class imagescaler::packages {
		package {
			[
				"imagemagick",
				"gs",
				"ffmpeg",
				"ffmpeg2theora",
				"librsvg2-bin",
				"djvulibre-bin",
				"netpbm",
				"gsfonts",
				"xfonts-scalable",
				"wikimedia-fonts",
				"xfonts-100dpi",
				"xfonts-75dpi",
				"xfonts-base",
				"xfonts-mplus",
				"ttf-liberation",
				"ttf-linux-libertine",
				"ttf-ubuntu-font-family",
				"libogg0",
				"libvorbisenc2",
				"libtheora0",
				"oggvideotools",
				"libvips15",
				"libvips-tools"]:
			ensure => latest;
		}

	# Additionally include packages which are shipped differently between
	# different Ubuntu versions.
	if ( $lsbdistcodename == 'lucid' ) {
		include imagescaler::packages::fonts::lucid
	} elsif ( $lsbdistcodename == 'precise' ) {
		include imagescaler::packages::fonts::precise
	}

}

# Fonts packages as shipped by Ubuntu Lucid
class imagescaler::packages::fonts::lucid {
	package {
		[
			"language-support-fonts-am",
			"language-support-fonts-ar",
			"language-support-fonts-as",
			"language-support-fonts-bn",
			"language-support-fonts-bo",
			"language-support-fonts-dz",
			"language-support-fonts-el",
			"language-support-fonts-fa",
			"language-support-fonts-gu",
			"language-support-fonts-he",
			"language-support-fonts-hi",
			"language-support-fonts-ii",
			"language-support-fonts-ja",
			"language-support-fonts-km",
			"language-support-fonts-kn",
			"language-support-fonts-ko",
			"language-support-fonts-lo",
			"language-support-fonts-ml",
			"language-support-fonts-mn",
			"language-support-fonts-mnc",
			"language-support-fonts-mr",
			"language-support-fonts-my",
			"language-support-fonts-ne",
			"language-support-fonts-or",
			"language-support-fonts-pa",
			"language-support-fonts-ta",
			"language-support-fonts-te",
			"language-support-fonts-th",
			"language-support-fonts-ur",
			"language-support-fonts-yi",
			"language-support-fonts-zh"]:
		ensure => latest;
	}
}

# Fonts packages as shipped by Ubuntu Precise
class imagescaler::packages::fonts::precise {
	package {
		[
			"ttf-alee",
			"ttf-arabeyes",
			"ttf-arphic-ukai",
			"ttf-arphic-uming",
			"ttf-bengali-fonts",
			"ttf-devanagari-fonts",
			"ttf-farsiweb",
			"ttf-gujarati-fonts",
			"ttf-kacst",
			"ttf-kannada-fonts",
			"ttf-khmeros",
			"ttf-lao",
			"ttf-malayalam-fonts",
			"ttf-manchufont",
			"ttf-mgopen",
			"ttf-nafees",
			"ttf-oriya-fonts",
			"ttf-punjabi-fonts",
			"ttf-sil-abyssinica",
			"ttf-sil-ezra",
			"ttf-sil-padauk",
			"ttf-sil-scheherazade",
			"ttf-sil-yi",
			"ttf-takao-gothic",
			"ttf-takao-mincho",
			"ttf-tamil-fonts",
			"ttf-telugu-fonts",
			"ttf-thai-tlwg",
			"ttf-tmuni",
			"ttf-unfonts-extra",
			"ttf-wqy-zenhei"]:
		ensure => latest;
		]
	}
}


class imagescaler::files {

	file {
		"/etc/wikimedia-image-scaler":
			content => "The presence of this file alters the apache configuration, to be suitable for image scaling.",
			#notify => Service[apache],
			owner => root,
			group => root,
			mode => 0644;
		"/etc/fonts/conf.d/70-yes-bitmaps.conf":
			ensure => absent;
		"/etc/fonts/conf.d/70-no-bitmaps.conf":
			ensure => "/etc/fonts/conf.avail/70-no-bitmaps.conf";
		"/a":
			ensure => directory,
			owner => root,
			group => root,
			mode => 755;
		"/a/magick-tmp":
			ensure => directory,
			owner => apache,
			group => root,
			mode => 755,
			require => File["/a"];
	}

}
