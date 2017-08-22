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
        'apertium-arg',
        'apertium-arg-cat',
        'apertium-bel',
        'apertium-bel-rus',
        'apertium-br-fr',
        'apertium-ca-it',
        'apertium-cat',
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
        'apertium-es-gl',
        'apertium-es-pt',
        'apertium-es-ro',
        'apertium-eu-en',
        'apertium-eu-es',
        'apertium-eus',
        'apertium-fra',
        'apertium-fra-cat',
        'apertium-fr-es',
        'apertium-hbs',
        'apertium-hbs-eng',
        'apertium-hbs-mkd',
        'apertium-hbs-slv',
        'apertium-hin',
        'apertium-id-ms',
        'apertium-isl',
        'apertium-isl-eng',
        'apertium-is-sv',
        'apertium-ita',
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
        'apertium-rus',
        'apertium-sme-nob',
        'apertium-spa',
        'apertium-spa-arg',
        'apertium-spa-cat',
        'apertium-spa-ita',
        'apertium-srd',
        'apertium-srd-ita',
        'apertium-swe',
        'apertium-swe-dan',
        'apertium-swe-nor',
        'apertium-tat',
        'apertium-urd',
        'apertium-urd-hin',
        'cg3',
        'giella-core',
        'giella-sme',
        'hfst',
        'lttoolbox',
    ]

    package { $packages:
        ensure => present,
        notify => Service['apertium-apy'],
    }

    # lint:ignore:arrow_alignment
    base::service_unit { 'apertium-apy':
        ensure  => present,
        upstart => upstart_template('apertium-apy'),
        systemd => systemd_template('apertium-apy'),
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

    logrotate::conf { 'apertium-apy':
        ensure  => present,
        content => template('apertium/logrotate.erb'),
    }
}
