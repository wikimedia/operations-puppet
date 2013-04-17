# == Define: pbuilder::image
#
# Creates a Debian distribution image
#
# === Parameters:
#
# [*namevar*]
#  The title will be split by dashes, the first part will be used to set the
#  *pbuilder* parameter unless it has been set, the second part is used to set
#  the *dist* parameter unless it has been set. Hence
#  'cowbuilder-precise-foobar' will ends up selecting the cowbuilder builder
#  and generate an image for the Precise distribution.
#
# [*pbuilder*]
#  The building program to use, either 'cowbuilder' or 'pbuilder'. Anything
#  else WILL force puppet to raise a failure.
#  *pbuilder* is not set by default which means the distribution will be
#  interpolated from the defined title (see *namevar*).
#
# [*dist*]
#  The distribution to build for (hardy, lucid, precise..).  *dist* is not
#  set by default which means the distribution will be interpolated from the
#  defined title (see *namevar*).
#
# === Examples
#
# Creating an image for cowbuilder and the raring distribution:
#
#   pbuilder::image { 'raring image for cowbuilder':
#     pbuilder => 'cowbuilder',
#     dist    => 'raring',
#   }
#
# Using title interpolation to generate cowbuilder images for both
# precise and lucid:
#
#   $images = [ 'cowbuilder-precise', 'cowbuilder-lucid' ],
#   pbuilder::image { $images: }
#
define pbuilder::image( $pbuilder=undef, $dist=undef ) {
  if $pbuilder {
    $realpbuilder = $pbuilder
  } else {
    $realpbuilder = values_at(split($title, '-',0))
  }
  if $dist {
    $realdist = $dist
  } else {
    $realdist = values_at(split($title, '-'),1)
  }

  notify { "Creating image ${title} (distribution: ${realdist}, pbuilder: ${realpbuilder})": }

  require packages

  case $realpbuilder {
    cowbuilder: {
      $base_option = '--basepath'
      $file_prefix = 'base-'
      $file_ext    = 'cow'
      $packages    = [ 'cowbuilder' ]
    }
    pbuilder: {
      $base_option = '--basetgz'
      $file_prefix = ''
      $file_ext    = 'tgz'
      $packages    = [ 'pbuilder' ]
    }
    default: { fail('Only package builder types supported are pbuilder and cowbuilder') }
  }

  $pbuilder_root = '/var/cache/pbuilder'

  $othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe'"
  $components = "--components 'main universe'"
  $image_file = "${pbuilder_root}/${file_prefix}${realdist}.${file_ext}"

  exec { "imaging ${realdist} for ${realpbuilder}":
    command   => "${realpbuilder} --create --distribution ${realdist} ${base_option} ${image_file} ${components} ${othermirror}",
    creates   => $image_file,
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    timeout   => 600,
    logoutput => on_failure,
  }
}
