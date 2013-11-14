#class to manage imagescaler font packages
class imagescaler::fonts {
    package {
        [
            'culmus', # bug 38946
            'culmus-fancy', # bug 38946

            'fonts-arabeyes',
            'fonts-lklug-sinhala', # bug 55462
            'fonts-arphic-ukai',
            'fonts-arphic-uming',
            'fonts-farsiweb',
            'fonts-kacst',
            'fonts-khmeros',
            'fonts-lao',
            'fonts-liberation',
            'fonts-linuxlibertine',
            'fonts-manchufont',
            'fonts-mgopen',
            'fonts-nafees',
            'fonts-sil-abyssinica',
            'fonts-sil-ezra',
            'fonts-sil-padauk',
            'fonts-sil-scheherazade',
            'fonts-sil-yi',
            'fonts-takao-gothic',
            'fonts-takao-mincho',
            'fonts-thai-tlwg',
            'fonts-tibetan-machine',
            'fonts-unfonts-extra',

            'gsfonts',
            'texlive-fonts-recommended',

            'ttf-alee',
            'ttf-bengali-fonts',
            'ttf-devanagari-fonts',
            'ttf-gujarati-fonts',
            'ttf-kannada-fonts',
            'ttf-lyx', # 'Computer Modern' - bug 38299
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
            'xfonts-scalable'
        ]:
        ensure => latest
    }
}

