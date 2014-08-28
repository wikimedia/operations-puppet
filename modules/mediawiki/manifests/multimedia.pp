# == Class: mediawiki::multimedia
#
# Provisions packages and configurations used by MediaWiki for image
# and video processing.
#
class mediawiki::multimedia {
    include ::mediawiki::packages::multimedia
    include ::mediawiki::packages::fonts

    file { '/etc/fonts/conf.d/70-no-bitmaps.conf':
        ensure  => link,
        target  => '/etc/fonts/conf.avail/70-no-bitmaps.conf',
        require => Package['fontconfig-config'],
    }

    file { '/tmp/magick-tmp':
        ensure => directory,
        owner  => 'apache',
        group  => 'root',
        mode   => '0755',
    }

    tidy { [ '/tmp', '/tmp/magick-tmp' ]:
        matches => [ 'gs_*', 'magick-*', 'localcopy_*', 'transform_*', 'vips-*.v' ],
        age     => '15m',
        type    => 'ctime',
        backup  => false,
        recurse => 1,
    }
}
