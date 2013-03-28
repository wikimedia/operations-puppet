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

	# == Define: image
	#
	# Creates a Debian distribution image
	#
	# === Parameters:
	# 
	# [*namevar*]
	#  When *dist* is not set, the title will be split by dashes and the 2nd element
	#  will be considerd to be the distribution name to use. Hence 'foo-precise-bar'
	#  ends up selecting the 'precise' distribution.
	#
	# [*builder*]
	#  The building program to use, either 'cowbuilder' or 'pbuilder'. Anything
	#  else we raise a failure. Builder is not interpolated from the title name.
	#  Defaults to 'pbuilder'.
	#
	# [*dist*]
	#  The distribution to build for (hardy, lucid, precise..). If it is not set,
	#  it will be interpolated from the define title (see *namevar*).
	#  Defaults to ''.
	# 
	# === Examples
	#
	# Creating an image for cowbuilder and the raring distribution:
	#
	#   image { 'raring image for cowbuilder':
	#     builder => 'cowbuilder',
	#     dist    => 'raring',
	#   }
	#
	# Using title interpolation to generate cowbuilder images for both
	# precise and lucid:
	#
	#   $images = [ 'fantastic123-precise', 'foo-lucid' ],
	#   image { $images: builder => 'cowbuilder' }
	#
	define image( $builder='pbuilder', $dist='' ) {
		if $dist == '' {
			$dist = values_at(split($title, '-'),1)
		} else {
			$realdist = $dist
		}

		notify { "Creating image $title (distribution: $realdist, builder: $builder)": }

		require packages

		case $builder {
			cowbuilder: {
				$base_option = '--basepath'
				$file_ext    = 'cow'
				$packages    = [ 'cowbuilder' ]
			}
			pbuilder: {
				$base_option = '--basetgz'
				$file_ext    = 'tgz'
				$packages    = [ 'pbuilder' ]
			}
			default: { fail('Only builder types supported are pbuilder and cowbuilder') }
		}

		$pbuilder_root = "/var/cache/pbuilder"

		$othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe'"
		$components = "--components 'main universe'"
		$image_file = "${pbuilder_root}/${realdist}.${file_ext}"

		exec { "imaging $realdist for $builder":
			command => "$builder --create --distribution ${realdist} ${base_option} ${image_file} ${components} ${othermirror}",
			creates => $image_file,
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			timeout => 600,
			logoutput => on_failure,
		}
	}

	# == Define: builder
	# Instantiate a debian packaging builder (such as pbuilder and cowbuilder) as
	# well as their distribution images.
	#
	# === Parameters:
	# [*namevar*]
	#  The name of the builder to use. Must be either 'cowbuilder' or 'pbuilder'.
	#  This must be a valid command name.  Defaults to 'pbuilder'.
	#
	# [*dists*]
	#  Array of distribution names to uses. Defaults to ['hardy','lucid','precise']
	#
	# [*defaultdist*]
	#  The default distribution to setup for the builder. Defaults to 'lucid'.
	#
	# === Examples
	#
	# Instancing cowbuilder for 'precise':
	#
	#   builder { 'cowbuilder':
	#     dists => 'precise',
	#     defaultdist => 'precise',
	#   }
	#
	# Instancing both pbuilder and cowbuilder:
	#
	#   builder { 'cowbuilder': }
	#   builder { 'pbuilder': }
	#
	define builder( $dists=["hardy", "lucid", "precise"], $defaultdist="lucid") {
		$builder = $title
		notify { "Calling builder '${builder}' on distributions '${dists}'": }

		package { $builder: ensure => latest }

		# Craft unique image titles such as cowbuilder-precise
		$images = prefix($dists, "${builder}-")
		image { $images:
			builder => $builder,
		}

		case $builder {
			cowbuilder: { $file_ext = 'cow' }
			pbuilder:   { $file_ext = 'tgz' }
			default: {
				fail('Only builder types supported are pbuilder and cowbuilder')
			}
		}

		file { "/var/cache/pbuilder/base.${file_ext}":
			require => Image["${title}-${defaultdist}"],
			ensure => "/var/cache/pbuilder/${defaultdist}.${file_ext}"
		}
	}

	include packages, defaults

	builder { 'cowbuilder': }
	builder { 'pbuilder': }

}
