# == Class: mediawiki::packages::multimedia
#
# Provisions packages used by MediaWiki for image and video processing.
#
class mediawiki::packages::multimedia {
    package { [
        'ffmpeg',
        'fontconfig-config',
        'ghostscript',
        'libimage-exiftool-perl',
        'libjpeg-turbo-progs',
        'libogg0',
        'libvips-tools',
        'libvorbisenc2',
        'netpbm',
        'oggvideotools',
    ]:
        ensure => present,
    }
}
