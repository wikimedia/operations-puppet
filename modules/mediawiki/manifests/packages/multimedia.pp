# == Class: mediawiki::packages::multimedia
#
# Provisions packages used by MediaWiki for image and video processing.
#
class mediawiki::packages::multimedia {
    if ubuntu_version('>= trusty') {
        $libav_package   = 'libav-tools'
        $libvips_package = 'libvips37'
    } else {
        $libav_package   = 'ffmpeg'
        $libvips_package = 'libvips15'
    }

    package { [
        $libav_package,
        $libvips_package,
        'ffmpeg2theora',
        'fontconfig-config',
        'ghostscript',
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
}
