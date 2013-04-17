# == Define: pbuilder::pbuilder
# Instantiate a debian packaging builder (such as pbuilder and cowbuilder) as
# well as their distribution images.
#
# === Parameters:
# [*namevar*]
#  The name of the builder to use. Must be either 'cowbuilder' or 'pbuilder'.
#  This must be a valid command name.  Defaults to 'pbuilder'.
#
# [*dists*]
#  Array of distribution names to uses.
#
# [*defaultdist*]
#  The default distribution to setup for the builder. If it is not listed
#  in dists, that will be generated as wel.
#
#
# === Examples
#
# Instancing cowbuilder for 'precise':
#
#   pbuilder::pbuilder { 'cowbuilder':
#     dists => 'precise',
#     defaultdist => 'precise',
#   }
#
# Instancing both pbuilder and cowbuilder:
#
#   pbuilder::pbuilder { 'cowbuilder':
#     dists => ['lucid', 'precise'],
#     defaultdist => 'precise',
#   }
#   pbuilder::pbuilder { 'pbuilder':
#     dists       => 'precise',
#     defaultdist => 'precise',
#   }
#
define pbuilder::pbuilder( $dists, $defaultdist) {
  $pbuilder = $title
  notify { "Calling package builder '${pbuilder}' on distributions '${dists}'": }

  package { $pbuilder: ensure => latest }

  # Craft unique image titles such as cowbuilder-precise
  $images = prefix($dists, "${pbuilder}-")
  image { $images:
    pbuilder => $pbuilder,
  }

  case $pbuilder {
    cowbuilder: {
      $file_prefix = 'base-'
      $file_ext = 'cow'
    }
    pbuilder: {
      $file_prefix = ''
      $file_ext = 'tgz'
    }
    default: {
      fail('Only package builder types supported are pbuilder and cowbuilder')
    }
  }

  file { "/var/cache/pbuilder/base.${file_ext}":
    require => Image["${title}-${defaultdist}"],
    ensure  => "/var/cache/pbuilder/${file_prefix}${defaultdist}.${file_ext}"
  }
}
