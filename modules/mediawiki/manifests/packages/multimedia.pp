# == Class: mediawiki::packages::multimedia
#
# Provisions packages used by MediaWiki for image and video processing.
#
class mediawiki::packages::multimedia {
    package { [
        'ffmpeg',
        'oggvideotools',
    ]:
        ensure => present,
    }
}
