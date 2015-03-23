# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
class apertium(){
    package { [
        'apertium',
        'apertium-af-nl',
        'apertium-apy',
        'apertium-en-ca',
        'apertium-en-es',
        'apertium-eo-en',
        'apertium-es-ca',
        'apertium-es-pt',
        'apertium-hbs',
        'apertium-hbs-eng',
        'apertium-hbs-mkd',
        'apertium-hbs-slv',
        'apertium-id-ms',
        'apertium-mk-bg',
        'apertium-mkd',
        'apertium-nno',
        'apertium-nno-nob',
        'apertium-nob',
        'apertium-pt-ca',
        'apertium-sv-da',
        'apertium-lex-tools',
        'lttoolbox'
    ]:
        ensure => present,
    }

    service { 'apertium-apy':
        ensure     => running,
        require    => Package['apertium-apy'],
    }
}
