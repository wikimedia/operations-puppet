# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include ::imagemagick::install

    # vips is needed for (rare) non-Thumbor scaling of TIFF/PNG uploads (T199938)
    require_package('python-imaging', 'tidy', 'libvips-tools')

    # PDF and DjVu
    require_package('ghostscript', 'djvulibre-bin', 'librsvg2-bin', 'libtiff-tools', 'poppler-utils')

    # ploticus for EasyTimeline extension (T237304)
    require_package('ploticus')

    # Score
    if os_version('debian == stretch') {
        apt::package_from_component { 'lilypond':
            component => 'component/lilypond',
            packages  => ['lilypond', 'lilypond-data']
        }
    } else {
        require_package('lilypond')
    }
    require_package('timidity', 'freepats', 'fluidsynth', 'fluid-soundfont-gs', 'fluid-soundfont-gm')

    require_package('firejail')

    # SecurePoll is incompatible with gpg2 (T209802)
    require_package('gnupg1')
}
