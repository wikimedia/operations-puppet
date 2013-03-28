# misc/package-builder.pp

class misc::package-builder {
	system_role { "misc::package-builder": description => "Debian package builder" }

	class packages {
		package { [
			"build-essential",
			"fakeroot",
			"debhelper",
			"git-buildpackage",
			"dupload",
			"libio-socket-ssl-perl",
			"libcrypt-ssleay-perl",
			"quilt",
			"cdbs",
			]: ensure => latest;
		}
	}

	class defaults {
		File { mode => 0444 }

		file {
			"/etc/devscripts.conf":
				content => template("misc/devscripts.conf.erb");
			"/etc/git-buildpackage/gbp.conf":
				require => Package["git-buildpackage"],
				content => template("misc/gbp.conf.erb");
			"/etc/dupload.conf":
				require => Package["dupload"],
				content => template("misc/dupload.conf.erb");
		}
	}

	class builder($type='pbuilder', $dists=["hardy", "lucid", "precise"], $defaultdist="lucid") {
		case $type {
			cowbuilder: {
				$base_option = '--basepath'
				$build_cmd   = 'cowbuilder'
				$file_ext    = 'cow'
				$packages    = [ 'cowbuilder' ]
			}
			pbuilder: {
				$base_option = '--basetgz'
				$build_cmd   = 'cowbuilder'
				$file_ext    = 'tgz'
				$packages    = [ 'pbuilder' ]
			}
			default: { fail('Only builder types supported are pbuilder and cowbuilder') }
		}

		class packages {
			package { $packages: ensure => latest }
		}
		
		define image {
			require packages

			$pbuilder_root = "/var/cache/pbuilder"

			$othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${title}-wikimedia main universe' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${title}-wikimedia main universe'"
			$components = "--components 'main universe'"

			exec { "$build_cmd --create --distribution ${title}":
				command => "$build_cmd --create --distribution ${title} ${base_option} ${pbuilder_root}/${title}.${file_ext} ${components} ${othermirror}",
				creates => "${pbuilder_root}/${title}.${file_ext}",
				path => "/bin:/sbin:/usr/bin:/usr/sbin",
				timeout => 600
			}
		}

		image { $dists: }

		file { "/var/cache/pbuilder/base.${file_ext}":
			require => Image[$defaultdist],
			ensure => "/var/cache/pbuilder/${defaultdist}.${file_ext}"
		}
	}

	include packages, defaults

	class { 'builder': type => 'cowbuilder' }
	class { 'builder': type => 'pbuilder' }

}
