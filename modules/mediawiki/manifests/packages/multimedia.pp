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
        'libjpeg-turbo-progs',
        'libogg0',
        'libtheora0',
        'libvips-tools',
        'libvorbisenc2',
        'netpbm',
        'oggvideotools',
        'libimage-exiftool-perl',
    ]:
        ensure => present,
    }

    if os_version('debian >= jessie || ubuntu >= trusty') {
        require_package('firejail')
    }
}
