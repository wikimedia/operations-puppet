# == Class: mediawiki::packages::multimedia
#
# Provisions packages used by MediaWiki for image and video processing.
#
class mediawiki::packages::multimedia {
    package { [
        'ffmpeg',
        'ffmpeg2theora',
        'fontconfig-config',
        'ghostscript',
        'libimage-exiftool-perl',
        'libjpeg-turbo-progs',
        'libogg0',
        'libtheora0',
        'libvips-tools',
        'libvorbisenc2',
        'netpbm',
        'oggvideotools',
    ]:
        ensure => present,
    }

    if os_version('debian == jessie') {
        apt::pin { 'ffmpeg':
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['ffmpeg'],
        }
    }
}
