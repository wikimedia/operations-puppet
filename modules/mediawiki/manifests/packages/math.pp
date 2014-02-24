# == mediawiki::packages::math
#
# Packages needed to render math using texvc.
#
# Extracted from the wikimedia-task-appserver package we used before puppet.
#
# This is a separate class so we can install the texlive packages without
# having to install wikimedia-task-appserver, for example when we do not want
# to get its dependencies installed (such as php5-apc on contint servers).
class mediawiki::packages::math {

    package { [
        'dvipng',
        'gsfonts',
        'texlive',
        'texlive-bibtex-extra',
        'texlive-font-utils',
        'texlive-fonts-extra',
        'texlive-lang-croatian',
        'texlive-lang-cyrillic',
        'texlive-lang-czechslovak',
        'texlive-lang-danish',
        'texlive-lang-dutch',
        'texlive-lang-finnish',
        'texlive-lang-french',
        'texlive-lang-german',
        'texlive-lang-greek',
        'texlive-lang-hungarian',
        'texlive-lang-italian',
        'texlive-lang-latin',
        'texlive-lang-mongolian',
        'texlive-lang-norwegian',
        'texlive-lang-other',
        'texlive-lang-polish',
        'texlive-lang-portuguese',
        'texlive-lang-spanish',
        'texlive-lang-swedish',
        'texlive-lang-vietnamese',
        'texlive-latex-extra',
        'texlive-math-extra',
        'texlive-pictures',
        'texlive-pstricks',
        'texlive-publishers',
        ]: ensure => present
    }

}
