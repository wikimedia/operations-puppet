# == Class: mediawiki::packages::tex
#
# Provisions packages used by MediaWiki for TeX rendering.
#
class mediawiki::packages::tex {
    package { [
        'texlive',
        'texlive-bibtex-extra',
        'texlive-font-utils',
        'texlive-fonts-extra',
        'texlive-generic-extra',
        'texlive-lang-all',
        'texlive-latex-extra',
        'texlive-pictures',
        'texlive-pstricks',
        'texlive-publishers',
    ]:
        ensure => present,
    }

    if os_version('debian >= stretch') {
        require_package('texlive-science')
    } else {
        require_package('texlive-math-extra')
    }
}
