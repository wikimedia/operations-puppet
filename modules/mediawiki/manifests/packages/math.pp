# == Class: mediawiki::packages::math
#
# Provisions packages used by MediaWiki for math rendering.
#
class mediawiki::packages::math {
    require_package('dvipng', 'gsfonts', 'make', 'ocaml', 'ploticus', 'texvc')
}
