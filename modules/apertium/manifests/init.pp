# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
# === Parameters
#
# [*log_dir*]
#   Place where apertium can put log files. Assumed to be already existing and
#   have write access to apertium user.
# [*port*]
#   Port where to run the apertium service. Defaults to 2737.

class apertium(
    $log_dir,
    $port=2737
) {
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

    file { '/etc/init.d/apertium-apy':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }

    service { 'apertium-apy':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => [
            File[$log_dir],
            File['/etc/init.d/apertium-apy']
        ],
        subscribe  => File['/etc/init/apertium-apy.conf'],
    }
}
