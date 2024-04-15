# SPDX-License-Identifier: Apache-2.0
# == Class: profile::beta::mediawiki_packages
#
# Provisions packages used by MediaWiki beta installations
# Package list from https://gerrit.wikimedia.org/r/plugins/gitiles/mediawiki/libs/Shellbox/+/refs/heads/master/.pipeline/blubber.yaml
#
class profile::beta::mediawiki_packages {

    if debian::codename::eq('buster') {
        apt::package_from_component { 'lilypond-buster':
            component => 'component/lilypond',
            packages  => ['lilypond', 'lilypond-data'],
            priority  => 1002, # Take precedence over main
        }
    }

    ensure_packages([
        'lame', # T317128
        'djvulibre-bin',
        'libtiff-tools',
        'poppler-utils',
        'imagemagick',
        'ghostscript',
        'fluidsynth',
        'fluid-soundfont-gs',
        'fluid-soundfont-gm',
        'fonts-noto',
        'python3-pygments',
        'perl',
        'ploticus',
        'librsvg2-bin',
    ])
}
