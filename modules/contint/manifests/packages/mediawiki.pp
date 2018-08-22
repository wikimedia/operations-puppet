
# === Class contint::packages::mediawiki
#
# MediaWiki packages needed for Continuous Integration
class contint::packages::mediawiki {


    # Math
    require_package('dvipng', 'gsfonts', 'make', 'ocaml', 'ploticus')

    if os_version('debian == jessie') {
        require_package('mediawiki-math-texvc')
    } else {
        require_package('texvc')
    }

    # TeX rendering.
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

    include ::imagemagick::install

    # vips is needed for (rare) non-Thumbor scaling of TIFF/PNG uploads (T199938)
    require_package('python-imaging', 'tidy', 'libvips-tools')

    # Pear
    require_package('php-pear', 'php-mail', 'php-mail-mime')

    # PDF and DjVu
    require_package('ghostscript', 'djvulibre-bin', 'librsvg2-bin', 'libtiff-tools', 'poppler-utils')

    # Score
    require_package('lilypond', 'timidity', 'freepats')

    # timidity recommends timidity-daemon, but we don't need it.
    package { 'timidity-daemon':
      ensure => absent,
    }

    require_package('firejail')
}
