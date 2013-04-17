# == Define: package-builder::image
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
# [*mirror*]
#  Main mirror to use. If not set, will use whatever mirror is configured
#  by default.
#
#  For `unstable` that will default to the US debian mirror.
#
#  Default: undef (or US Debian mirror for `unstable` dist)
#
# [*components*]
#  The repositories to use from the mirrors. Should be an array or a space
#  delimited string. This is passed to the pbuilder package with
#  `--components`.
#  Default: ['main', 'universe']
#
# [*dist*]
#  The distribution to build for (hardy, lucid, precise..).  *dist* is not
#  set by default which means the distribution will be interpolated from the
#  defined title (see *namevar*).
#  When using the dist 'unstable', the repository will be pointed to a
#  debian.org mirror.
#
# === Examples
#
# Creating an image for cowbuilder and the raring distribution:
#
#   package-builder::image { 'raring image for cowbuilder':
#     pbuilder => 'cowbuilder',
#     dist    => 'raring',
#   }
#
# Using title interpolation to generate cowbuilder images for both
# precise and lucid:
#
#   $images = [ 'cowbuilder-precise', 'cowbuilder-lucid' ],
#   package-builder::image { $images: }
#
define package-builder::image( $pbuilder=undef, $mirror=undef, $components=['main','universe'], $dist=undef ) {
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

  $realcomponents = join($components, ' ')

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

  # Hack to support Debian unstable
  case $realdist {
    'unstable': {
      $debootstrapopts = '--debootstrapopts --keyring=/usr/share/keyrings/debian-archive-keyring.gpg'
      # Make sure we override the Ubuntu default mirror
      if $mirror == undef {
        $mirror = 'http://ftp.us.debian.org/debian'
      }
      $othermirror = "--othermirror 'deb-src http://ftp.us.debian.org/debian ${realdist} main'"
      $components = "--components 'main'"
    }
    default: {
      $debootstrapopts = ''
      $othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe'"
      $components = "--components 'main universe'"
    }
  }

  if $mirror {
    $realmirror = "--mirror ${mirror}"
  }

  $pbuilder_root = '/var/cache/pbuilder'

  $othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia ${realcomponents}' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia ${realcomponents}'"
  $image_file = "${pbuilder_root}/${file_prefix}${realdist}.${file_ext}"

  exec { "imaging ${realdist} for ${realpbuilder}":
    command   => "${realpbuilder} --create --distribution ${realdist} ${base_option} ${image_file} --components '${realcomponents}' ${realmirror} ${othermirror} ${debootstrapopts}",
    creates   => $image_file,
    path      => '/bin:/sbin:/usr/bin:/usr/sbin',
    timeout   => 600,
    logoutput => on_failure,
  }
}
