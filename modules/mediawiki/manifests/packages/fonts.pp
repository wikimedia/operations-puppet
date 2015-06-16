# == Class: mediawiki::packages::fonts
#
# Provisions font packages used by MediaWiki.
#
class mediawiki::packages::fonts {

    if os_version( 'debian >= jessie') {

        $font_packages = [
        'culmus-fancy',              # T40946
        'culmus',                    # T40946
        'fonts-alee',
        'fonts-arabeyes',
        'fonts-arphic-ukai',
        'fonts-arphic-uming',
        'fonts-beng',
        'fonts-dejavu-core',         # T65206
        'fonts-dejavu-extra',        # T65206
        'fonts-deva',
        'fonts-farsiweb',
        'fonts-gujr',
        'fonts-guru',
        'fonts-ipafont-mincho',      # T66002
        'fonts-kacst',
        'fonts-khmeros',
        'fonts-knda',
        'fonts-lao',
        'fonts-liberation',
        'fonts-linuxlibertine',
        'fonts-lklug-sinhala',       # T57462
        'fonts-lyx',                 # T40299
        'fonts-manchufont',
        'fonts-mgopen',
        'fonts-mlym',
        'fonts-nafees',
        'fonts-orya',
        'fonts-sil-abyssinica',
        'fonts-sil-ezra',
        'fonts-sil-nuosusil',        # T83288
        'fonts-sil-padauk',
        'fonts-sil-scheherazade',
        'fonts-takao-gothic',
        'fonts-takao-mincho',
        'fonts-taml',
        'fonts-telu',
        'fonts-thai-tlwg',
        'fonts-tibetan-machine',
        'fonts-unfonts-core',
        'fonts-unfonts-extra',
        'fonts-vlgothic',            # T66002
        'fonts-wqy-zenhei',
        'texlive-fonts-recommended',
        'xfonts-100dpi',
        'xfonts-75dpi',
        'xfonts-base',
        'xfonts-mplus',
        'xfonts-scalable',
        ]

   } else {

        $font_packages = [
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
        'ttf-alee',
        'ttf-bengali-fonts',
        'ttf-dejavu-core',           # T65206
        'ttf-dejavu-extra',          # T65206
        'ttf-devanagari-fonts',
        'ttf-gujarati-fonts',
        'ttf-kannada-fonts',
        'ttf-kochi-gothic',          # T66002
        'ttf-kochi-mincho',          # T66002
        'ttf-lyx',                   # T40299
        'ttf-malayalam-fonts',
        'ttf-oriya-fonts',
        'ttf-punjabi-fonts',
        'ttf-tamil-fonts',
        'ttf-telugu-fonts',
        'ttf-ubuntu-font-family',
        'ttf-wqy-zenhei',
        'xfonts-100dpi',
        'xfonts-75dpi',
        'xfonts-base',
        'xfonts-mplus',
        'xfonts-scalable',
        ]
}

    ensure_packages($font_packages)

    # T84842
    if os_version('ubuntu >= trusty || debian >= jessie') {
        package { ['fonts-crosextra-carlito', 'fonts-crosextra-caladea']:
            ensure => present,
        }
    }
}
