class apertium::packages {

    package { [
        'apertium-apy',
        'apertium-es-ca',
        'apertium-es-pt',
        'apertium-pt-ca',
        'apertium-lex-tools',
        'lttoolbox',
    ]:
        ensure => present,
    }

}
