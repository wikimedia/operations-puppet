# imagescaler.pp

# Virtual resource for the monitoring server
@monitor_group { "image_scalers": description => "image scalers" }

class imagescaler::cron {
	cron { removetmpfiles:
		command => "for dir in /tmp /a/magick-tmp; do find \$dir -ignore_readdir_race -type f \\( -name 'gs_*' -o -name 'magick-*' \\) -cmin +15 -exec rm -f {} \\;; done",
		user => root,
		minute => '*/5',
		ensure => present
	}
}

class imagescaler::packages {

	include imagescaler::packages::fonts

	package {
		[
			"imagemagick",
			"ghostscript",
			"ffmpeg",
			"ffmpeg2theora",
			"librsvg2-bin",
			"djvulibre-bin",
			"netpbm",
			"libogg0",
			"libvorbisenc2",
			"libtheora0",
			"oggvideotools",
			"libvips15",
			"libvips-tools",
			"libimage-exiftool-perl"]:
		ensure => latest;
	}

}

class imagescaler::packages::fonts {
	package {
		[
			"gsfonts",
			"texlive-fonts-recommended",
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
			"ttf-liberation",
			"ttf-linux-libertine",
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
			"ttf-ubuntu-font-family",
			"ttf-unfonts-extra",
			"ttf-wqy-zenhei",
			"xfonts-100dpi",
			"xfonts-75dpi",
			"xfonts-base",
			"xfonts-mplus",
			"xfonts-scalable"]:
		ensure => latest;
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
