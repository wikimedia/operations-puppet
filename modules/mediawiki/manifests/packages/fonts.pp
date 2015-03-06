# == Class: mediawiki::packages::fonts
#
# Provisions font packages used by MediaWiki.
#
class mediawiki::packages::fonts {
    package { [
        'fonts-arabeyes',
        'fonts-arphic-ukai',
        'fonts-arphic-uming',
        'fonts-farsiweb',
        'fonts-kacst',
        'fonts-khmeros',
        'fonts-lao',
        'fonts-liberation',
        'ttf-linux-libertine',
        'fonts-manchufont',
        'fonts-mgopen',
        'fonts-nafees',
        'fonts-sil-abyssinica',
        'fonts-sil-ezra',
        'fonts-sil-padauk',
        'fonts-sil-scheherazade',
        'fonts-takao-gothic',
        'fonts-takao-mincho',
        'fonts-thai-tlwg',
        'fonts-tibetan-machine',
        'fonts-unfonts-core',
        'texlive-fonts-recommended',
        'ttf-alee',
        'ttf-bengali-fonts',
        'ttf-devanagari-fonts',
        'ttf-gujarati-fonts',
        'fonts-knda',
        'ttf-malayalam-fonts',
        'fonts-oriya',
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
        'fonts-sil-nuosusil',        # RT 6500
        'culmus',                    # Bug 38946
        'culmus-fancy',              # Bug 38946
        'fonts-lklug-sinhala',       # Bug 55462
        'fonts-vlgothic',            # Bug 64002
        'ttf-dejavu-core',           # Bug 63206
        'ttf-dejavu-extra',          # Bug 63206
        'ttf-kochi-gothic',          # Bug 64002
        'ttf-kochi-mincho',          # Bug 64002
        'ttf-lyx',                   # Bug 38299
    ]:
        ensure => present,
    }
}
