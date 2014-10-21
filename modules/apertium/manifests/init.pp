# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
class apertium(){
    package { [
        'apertium',
        'apertium-apy',
        'apertium-es-ca',
        'apertium-es-pt',
        'apertium-pt-ca',
        'apertium-lex-tools',
        'lttoolbox'
    ]:
        ensure => present,
    }

    service { 'apertium-apy':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => Package['apertium-apy'],
    }
}
