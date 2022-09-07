# SPDX-License-Identifier: Apache-2.0
# == Class: profile::beta::mediawiki_packages
#
# Provisions packages used by MediaWiki beta installations
# Package list from https://gerrit.wikimedia.org/r/plugins/gitiles/mediawiki/libs/Shellbox/+/refs/heads/master/.pipeline/blubber.yaml
#
class profile::beta::mediawiki_packages {
    ensure_packages([
        'lame', # T317128
        'djvulibre-bin',
        'libtiff-tools',
        'poppler-utils',
        'lilypond/buster-backports',
        'lilypond-data/buster-backports',
        'imagemagick',
        'ghostscript',
        'fluidsynth',
        'fluid-soundfont-gs',
        'fluid-soundfont-gm',
        'fonts-noto',
        'fonts-noto-cjk',
        'python3-pygments',
        'perl',
        'ploticus',
        'librsvg2-bin',
    ])
}
