# == Class: mediawiki::packages::math
#
# Provisions packages used by MediaWiki for math rendering.
#
class mediawiki::packages::math {
    package { [
        'dvipng',
        'gsfonts',
        'make',
        'ocaml',
        'ploticus',
        'mediawiki-math-texvc',
    ]:
        ensure => present,
    }
}
