# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
class apertium(){
    package { [
        'apertium',
        'apertium-apy',
        'apertium-en-ca',
        'apertium-eo-en',
        'apertium-en-es',
        'apertium-es-ca',
        'apertium-es-pt',
        'apertium-id-ms',
        'apertium-nno-nob',
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
