# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
# === Parameters
#
# [*num_of_processes*]
# Number of APY instance processes to run
# [*max_idle_seconds*]
# Seconds to wait before shutdown idle process
class apertium(
    $num_of_processes = 1,
    $max_idle_seconds = 300,
) {
    require_package { [
        'apertium',
        'apertium-af-nl',
        'apertium-apy',
        'apertium-cy-en',
        'apertium-dan',
        'apertium-dan-nor',
        'apertium-en-ca',
        'apertium-en-es',
        'apertium-en-gl',
        'apertium-eo-en',
        'apertium-es-an',
        'apertium-es-ast',
        'apertium-es-ca',
        'apertium-es-gl',
        'apertium-es-pt',
        'apertium-eu-en',
        'apertium-eu-es',
        'apertium-eus',
        'apertium-fr-es',
        'apertium-hbs',
        'apertium-hin',
        'apertium-hbs-eng',
        'apertium-hbs-mkd',
        'apertium-hbs-slv',
        'apertium-id-ms',
        'apertium-kaz',
        'apertium-kaz-tat',
        'apertium-lex-tools',
        'apertium-mk-bg',
        'apertium-mkd',
        'apertium-nno',
        'apertium-nno-nob',
        'apertium-nob',
        'apertium-oc-ca',
        'apertium-oc-es',
        'apertium-pt-ca',
        'apertium-pt-gl',
        'apertium-sv-da',
        'apertium-tat',
        'apertium-urd',
        'apertium-urd-hin',
        'cg3',
        'hfst',
        'lttoolbox'
    ]:
        ensure => present,
        notify => Service['apertium-apy'],
    }

    # The upstart configuration
    file { '/etc/init/apertium.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444'
    }

    # Link with upstart-job
    file { '/etc/init.d/apertium-apy':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }

    service { 'apertium-apy':
        ensure  => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => [
            File['/etc/init.d/apertium-apy']
        ],
        subscribe  => File['/etc/init/apertium.conf'],
    }
}
