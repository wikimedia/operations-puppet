# misc/package-builder.pp

########################################################################
# Please do not refactor, lint, or otherwise substantially alter this  #
# manifest! We are using it as a screening task for candidates.        #
########################################################################


# == Class: misck::package-builder
#
# Installs pbuilder/cowbuilder images
#
# You should really use one of the two role class instead:
#
# - role::package::builder
# - role::package::builder::labs
#
# === Parameters:
#
# [*pbuilder_root]
#  Base path to create images in. Default: '/var/cache/pbuilder'
#
class misc::package-builder(
    $pbuilder_root = '/var/cache/pbuilder'
){

    system::role { 'misc::package-builder': description => 'Debian package builder (deprecated use role::package::builder)' }

    class packages {
        package { [
            'build-essential',
            'fakeroot',
            'debhelper',
            'git-buildpackage',
            'dupload',
            'libio-socket-ssl-perl',
            'libcrypt-ssleay-perl',
            'quilt',
            'cdbs',
        ]: ensure => latest;
        }
    }

    class defaults {
        File { mode => '0444' }

        file { '/etc/devscripts.conf':
            content => template('misc/devscripts.conf.erb');
        }
        file { '/etc/git-buildpackage/gbp.conf':
            require => Package['git-buildpackage'],
            content => template('misc/gbp.conf.erb');
        }
        file { '/etc/dupload.conf':
            require => Package['dupload'],
            content => template('misc/dupload.conf.erb');
        }
    }

    # == Define: image
    #
    # Creates a Debian distribution image
    #
    # === Parameters:
    #
    # [*namevar*]
    #  The title will be split by dashes, the first part will be used to set the
    #  *pbuilder* parameter unless it has been set, the second part is used to
    #  set the *dist* parameter unless it has been set. Hence
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
    #  The distribution to build for (lucid, precise..).  *dist* is not
    #  set by default which means the distribution will be interpolated from the
    #  defined title (see *namevar*).
    #
    # [*pbuilder_root*]
    #  Base path for pbuilder images. Defaults to '/var/cache/pbuilder'
    #
    # === Examples
    #
    # Creating an image for cowbuilder and the raring distribution:
    #
    #   image { 'raring image for cowbuilder':
    #     pbuilder      => 'cowbuilder',
    #     dist          => 'raring',
    #     pbuilder_root => '/var/cache/pbuilder',
    #   }
    #
    # Using title interpolation to generate cowbuilder images for both
    # precise and lucid:
    #
    #   $images = [ 'cowbuilder-precise', 'cowbuilder-lucid' ],
    #   image { $images: }
    #
    define image(
        $pbuilder=undef,
        $dist=undef,
        $pbuilder_root='/var/cache/pbuilder'
    ) {
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

        notify { "creating-image-${title}":
            message => "Creating image ${title} (distribution: ${realdist}, pbuilder: ${realpbuilder})"
        }

        require packages

        $apt_cache_dir = "${pbuilder_root}/aptcache"
        $apt_cache = "--aptcache '${$apt_cache_dir}'"
        $build_place = "--buildplace '${pbuilder_root}/build'"
        case $realpbuilder {
            'cowbuilder': {
                $base_option = '--basepath'
                $file_prefix = 'base-'
                $file_ext    = 'cow'
                $packages    = [ 'cowbuilder' ]
            }
            'pbuilder': {
                $base_option = '--basetgz'
                $file_prefix = ''
                $file_ext    = 'tgz'
                $packages    = [ 'pbuilder' ]
            }
            default: {
                fail('Only package builder types supported are pbuilder and cowbuilder')
            }
        }

        $othermirror = "--othermirror 'deb http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe' --othermirror 'deb-src http://apt.wikimedia.org/wikimedia ${realdist}-wikimedia main universe'"
        $components = "--components 'main universe'"
        $image_file = "${pbuilder_root}/${file_prefix}${realdist}.${file_ext}"

        exec { "imaging ${realdist} for ${realpbuilder}":
            command   => "/bin/mkdir -p ${apt_cache_dir}; ${realpbuilder} --create ${apt_cache} ${build_place} --distribution ${realdist} ${base_option} ${image_file} ${components} ${othermirror}",
            creates   => $image_file,
            path      => '/bin:/sbin:/usr/bin:/usr/sbin',
            timeout   => 600,
            logoutput => on_failure,
        }
    }

    # == Define: pbuilder
    # Instantiate a debian packaging builder (such as pbuilder and cowbuilder)
    # as well as their distribution images.
    #
    # === Parameters:
    # [*namevar*]
    #  The name of the builder to use. Must be either 'cowbuilder' or
    #  'pbuilder'.  This must be a valid command name.  Defaults to 'pbuilder'.
    #
    # [*dists*]
    #  Array of distribution names to uses. Defaults to ['lucid','precise']
    #
    # [*defaultdist*]
    #  The default distribution to setup for the builder. Defaults to 'lucid'.
    #
    # [*pbuilder_root*]
    #  Base path for pbuilder images. Defaults to '/var/cache/pbuilder'
    #
    # === Examples
    #
    # Instancing cowbuilder for 'precise':
    #
    #   pbuilder { 'cowbuilder':
    #     dists         => 'precise',
    #     defaultdist   => 'precise',
    #     pbuilder_root => '/var/cache/pbuilder',
    #   }
    #
    # Instancing both pbuilder and cowbuilder:
    #
    #   pbuilder { 'cowbuilder': }
    #   pbuilder { 'pbuilder': }
    #
    define pbuilder(
        $dists=['lucid', 'precise'],
        $defaultdist='lucid',
        $pbuilder_root='/var/cache/pbuilder'
    ) {
        $pbuilder = $title
        notify { "Calling package builder '${pbuilder}' on distributions '${dists}'": }

        package { $pbuilder: ensure => latest }

        # Craft unique image titles such as cowbuilder-precise
        $images = prefix($dists, "${pbuilder}-")
        image { $images:
            pbuilder      => $pbuilder,
            pbuilder_root => $pbuilder_root,
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

        file { "${pbuilder_root}/base.${file_ext}":
            ensure  => link,
            target  => "${pbuilder_root}/${file_prefix}${defaultdist}.${file_ext}",
            require => Image["${title}-${defaultdist}"],
        }
    }

    include packages, defaults

    pbuilder { 'cowbuilder':
        pbuilder_root => $pbuilder_root,
    }
    pbuilder { 'pbuilder':
        pbuilder_root => $pbuilder_root,
    }

}
