# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include imagemagick::install

    ensure_packages([
        'fluidsynth', 'fluid-soundfont-gs', 'fluid-soundfont-gm', 'firejail',
        # vips is needed for (rare) non-Thumbor scaling of TIFF/PNG uploads (T199938)
        'tidy', 'libvips-tools',
        # PDF and DjVu
        'ghostscript', 'djvulibre-bin', 'librsvg2-bin', 'libtiff-tools', 'poppler-utils',
        # ploticus for EasyTimeline extension (T237304)
        'ploticus',
        # SecurePoll is incompatible with gpg2 (T209802)
        'gnupg1',
    ])

    # Score
    ensure_packages('lilypond')

    # Used by captcha.py from ConfirmEdit extension (used to generate captchas)
    ensure_packages(['python-pil', 'python3-pil'])
}
