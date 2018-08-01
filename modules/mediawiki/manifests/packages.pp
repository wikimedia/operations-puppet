# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include ::mediawiki::packages::tex

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

    # Math rendering
    require_package('dvipng', 'gsfonts', 'make', 'ocaml', 'ploticus', 'texvc')

    require_package('firejail')
}
