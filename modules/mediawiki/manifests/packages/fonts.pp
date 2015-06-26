# == Class: mediawiki::packages::fonts
#
# Provisions font packages used by MediaWiki.
#
class mediawiki::packages::fonts {

        $font_pkgs_common = [
        'culmus-fancy',              # T40946
        'culmus',                    # T40946
        'fonts-arabeyes',
        'fonts-arphic-ukai',
        'fonts-arphic-uming',
        'fonts-farsiweb',
        'fonts-kacst',
        'fonts-khmeros',
        'fonts-lao',
        'fonts-liberation',
        'fonts-linuxlibertine',
        'fonts-lklug-sinhala',       # T57462
        'fonts-manchufont',
        'fonts-mgopen',
        'fonts-nafees',
        'fonts-sil-abyssinica',
        'fonts-sil-ezra',
        'fonts-sil-nuosusil',        # T83288
        'fonts-sil-padauk',
        'fonts-sil-scheherazade',
        'fonts-takao-gothic',
        'fonts-takao-mincho',
        'fonts-thai-tlwg',
        'fonts-tibetan-machine',
        'fonts-unfonts-core',
        'fonts-unfonts-extra',
        'fonts-vlgothic',            # T66002
        'texlive-fonts-recommended',
        'xfonts-base',
        'xfonts-75dpi',
        'xfonts-100dpi',
        'xfonts-mplus',
        'xfonts-scalable',
        ]

        $fonts_pkgs_new = [
        'fonts-alee',
        'fonts-beng','
        'fonts-crosextra-carlito', # T84842
        'fonts-crosextra-caladea', # T84842
        'fonts-dejavu-core',
        'fonts-dejavu-extra',
        'fonts-deva',
        'fonts-gujr',
        'fonts-guru',
        'fonts-ipafont-mincho',
        'fonts-knda',
        'fonts-lyx',
        'fonts-mlym',
        'fonts-orya',
        'fonts-taml',
        'fonts-telu',
        'fonts-wqy-zenhei',
        ]

        $font_pkgs_old = [
        'ttf-alee',
        'ttf-bengali-fonts',
        'ttf-dejavu-core',
        'ttf-dejavu-extra',
        'ttf-devanagari-fonts',
        'ttf-gujarati-fonts',
        'ttf-kannada-fonts',
        'ttf-kochi-gothic',
        'ttf-kochi-mincho',
        'ttf-lyx',
        'ttf-malayalam-fonts',
        'ttf-oriya-fonts',
        'ttf-punjabi-fonts',
        'ttf-tamil-fonts',
        'ttf-telugu-fonts',
        'ttf-ubuntu-font-family',
        'ttf-wqy-zenhei',
        ]
}

    ensure_packages($font_pkgs_common)

    if os_version('debian >= jessie') {
        ensure_packages($font_pkgs_new)
    } else {
        ensure_packages($font_pkgs_old)
    }
}
