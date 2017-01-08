# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
# === Parameters
#
# [*num_of_processes*]
#   Number of APY instance processes to run.
# [*max_idle_seconds*]
#   Seconds to wait before shutdown idle process.
# [*uid*]
#   The username apertium-apy will run with.
# [*gid*]
#   The group apertium-apy will run with.
class apertium(
    $num_of_processes = 1,
    $max_idle_seconds = 300,
    $uid = 'apertium',
    $gid = 'apertium',
) {

    include ::service::configuration

    $log_dir = "${::service::configuration::log_dir}/apertium"

    $packages = [
        'apertium',
        'apertium-af-nl',
        'apertium-apy',
        'apertium-br-fr',
        'apertium-ca-it',
        'apertium-cy-en',
        'apertium-dan',
        'apertium-dan-nor',
        'apertium-en-ca',
        'apertium-en-es',
        'apertium-en-gl',
        'apertium-eo-ca',
        'apertium-eo-en',
        'apertium-eo-es',
        'apertium-eo-fr',
        'apertium-es-ast',
        'apertium-es-ca',
        'apertium-es-gl',
        'apertium-es-it',
        'apertium-es-pt',
        'apertium-es-ro',
        'apertium-eu-en',
        'apertium-eu-es',
        'apertium-eus',
        'apertium-fr-es',
        'apertium-hbs',
        'apertium-hbs-eng',
        'apertium-hbs-mkd',
        'apertium-hbs-slv',
        'apertium-hin',
        'apertium-id-ms',
        'apertium-is-sv',
        'apertium-isl',
        'apertium-isl-eng',
        'apertium-kaz',
        'apertium-kaz-tat',
        'apertium-lex-tools',
        'apertium-mk-bg',
        'apertium-mlt-ara',
        'apertium-nno',
        'apertium-nno-nob',
        'apertium-nob',
        'apertium-oc-ca',
        'apertium-oc-es',
        'apertium-pt-ca',
        'apertium-pt-gl',
        'apertium-tat',
        'apertium-urd',
        'apertium-urd-hin',
        'cg3',
        'hfst',
        'lttoolbox',
        'apertium-arg',
        'apertium-arg-cat',
        'apertium-cat',
        'apertium-fra',
        'apertium-fra-cat',
        'apertium-ita',
        'apertium-sme-nob',
        'apertium-spa',
        'apertium-spa-arg',
        'apertium-srd',
        'apertium-srd-ita',
        'apertium-swe',
        'apertium-swe-dan',
        'apertium-swe-nor',
        'giella-core',
        'giella-sme',
    ]

    package { $packages:
        ensure => present,
        notify => Service['apertium-apy'],
    }

    # lint:ignore:arrow_alignment
    base::service_unit { 'apertium-apy':
        ensure  => present,
        upstart => true,
        systemd => true,
        refresh => true,
        service_params => {
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        },
    }
    # lint:endignore
    file { $log_dir:
        ensure => directory,
        owner  => $uid,
        group  => 'root', # This on purpose for logrotate to behave
        mode   => '0755',
        before => Service['apertium-apy'],
    }

    file { '/etc/logrotate.d/apertium-apy':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('apertium/logrotate.erb'),
    }
}
