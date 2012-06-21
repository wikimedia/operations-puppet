# misc/package-builder.pp

class misc::package-builder {
	system_role { "misc::package-builder": description => "Debian package builder" }

	include generic::packages::git-core

	class packages {
		package { [ "build-essential", "fakeroot", "debhelper", "git-buildpackage", "dupload", "libio-socket-ssl-perl", "quilt", "cdbs" ]:
			ensure => latest;
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

	class pbuilder($dists=["hardy", "lucid", "precise"], $defaultdist="lucid") {
		class packages {
			package { "pbuilder": ensure => latest }
		}
		
		define image{
			require packages

			$pbuilder_root = "/var/cache/pbuilder"

			$othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${title}-wikimedia main universe' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${title}-wikimedia main universe'"

			exec { "pbuilder --create --distribution ${title}":
				command => "pbuilder --create --distribution ${title} --basetgz ${pbuilder_root}/${title}.tgz ${othermirror}",
				creates => "${pbuilder_root}/${title}.tgz",
				path => "/bin:/sbin:/usr/bin:/usr/sbin",
				timeout => 600
			}
		}

		image { $dists: }

		file { "/var/cache/pbuilder/base.tgz":
			require => Image[$defaultdist],
			ensure => "/var/cache/pbuilder/${defaultdist}.tgz"
		}
	}

	include packages, defaults, pbuilder
}
