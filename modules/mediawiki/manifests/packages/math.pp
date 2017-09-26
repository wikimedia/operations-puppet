# == Class: mediawiki::packages::math
#
# Provisions packages used by MediaWiki for math rendering.
#
class mediawiki::packages::math {
    require_package('dvipng', 'gsfonts', 'make', 'ocaml', 'ploticus')

    if os_version('ubuntu == trusty' or os_version('debian == jessie') {
        require_package('mediawiki-math-texvc')
    } else {
        require_package('texvc')
    }
}
