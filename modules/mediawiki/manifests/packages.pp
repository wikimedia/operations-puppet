# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include imagemagick::install

    ensure_packages([
        'fluidsynth', 'fluid-soundfont-gs', 'fluid-soundfont-gm', 'firejail',
        # PDF and DjVu
        'ghostscript', 'djvulibre-bin', 'librsvg2-bin', 'libtiff-tools', 'poppler-utils',
        # SecurePoll is incompatible with gpg2 (T209802)
        'gnupg1',
    ])

    # Used by captcha.py from ConfirmEdit extension (used to generate captchas)
    ensure_packages(['python-pil', 'python3-pil'])
}
