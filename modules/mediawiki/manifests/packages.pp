# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include imagemagick::install

    ensure_packages([
        'fluidsynth', 'fluid-soundfont-gs', 'fluid-soundfont-gm', 'firejail',
        # vips is needed for (rare) non-Thumbor scaling of TIFF/PNG uploads (T199938)
        'libvips-tools',
        # PDF and DjVu
        'ghostscript', 'djvulibre-bin', 'librsvg2-bin', 'libtiff-tools', 'poppler-utils',
        # SecurePoll is incompatible with gpg2 (T209802)
        'gnupg1',
    ])

    package {'tidy':
        ensure => absent
    }

    # Used by captcha.py from ConfirmEdit extension (used to generate captchas)
    ensure_packages(['python-pil', 'python3-pil'])
}
