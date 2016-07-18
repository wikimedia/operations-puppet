# == Class: mediawiki::multimedia
#
# Provisions packages and configurations used by MediaWiki for image
# and video processing.
#
class mediawiki::multimedia {
    include ::mediawiki::packages::multimedia
    include ::mediawiki::packages::fonts
    include ::mediawiki::users
    include ::mediawiki::firejail

    file { '/etc/fonts/conf.d/70-no-bitmaps.conf':
        source  => 'puppet:///modules/mediawiki/fontconfig-no-bitmaps.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['fontconfig-config'],
    }

    file { '/tmp/magick-tmp':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'root',
        mode   => '0755',
    }

    tidy { [ '/tmp', '/tmp/magick-tmp' ]:
        matches => [ '*.png', 'EasyTimeline.*', 'gs_*', 'localcopy_*', 'magick-*', 'transform_*', 'vips-*.v' ],
        age     => '2h',
        type    => 'ctime',
        backup  => false,
        recurse => 1,
    }
}
