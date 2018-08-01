# == Class: mediawiki::packages::tex
#
# Provisions packages used by MediaWiki for TeX rendering.
#
class mediawiki::packages::tex {
    require_package('texlive', 'texlive-bibtex-extra', 'texlive-science', 'texlive-font-utils')
    require_package('texlive-fonts-extra', 'texlive-generic-extra', 'texlive-lang-all', 'texlive-pictures')
    require_package('texlive-latex-extra', 'texlive-pstricks', 'texlive-publishers')
}
