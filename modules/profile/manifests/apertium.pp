# == Class: apertium
#
# Apertium is a backend Machine Translation service for the Content Translation.
# https://www.mediawiki.org/wiki/Content_translation/Apertium
#
# === Parameters
#
# [*num_of_processes*]

# [*max_idle_seconds*]
#
class profile::apertium {
    require ::service::configuration

    # Port we're listening on
    $port = 2737
    # Number of APY instance processes to run.
    $num_of_processes = 1
    # Seconds to wait before shutting down an idle process.
    $max_idle_seconds = 300
    # User and group
    $uid = 'apertium'
    $gid = 'apertium'

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
        'apertium-cat-srd',
        'apertium-crh',
        'apertium-crh-tur',
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
        'apertium-rus-ukr',
        'apertium-separable',
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
        'apertium-tur',
        'apertium-ukr',
        'apertium-urd',
        'apertium-urd-hin',
        'cg3',
        'giella-core',
        'giella-sme',
        'hfst',
        'lttoolbox',
        'python3-streamparser',
    ]

    # Use python3-tornado 4.4.3-1 since newer verions of apertium-apy require it
    apt::pin { 'python3-tornado':
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['apertium-apy'],
    }

    package { $packages:
        ensure => present,
        notify => Service['apertium-apy'],
    }

    # lint:ignore:arrow_alignment
    base::service_unit { 'apertium-apy':
        ensure  => present,
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

    logrotate::rule { 'apertium-apy':
        ensure        => present,
        file_glob     => "${log_dir}/apertium-apy.log ${log_dir}/apertium-apy.err",
        frequency     => 'daily',
        copy_truncate => true,
        missing_ok    => true,
        compress      => true,
        not_if_empty  => true,
        rotate        => 15,
    }

    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $port,
    }

    monitoring::service { 'apertium':
        description   => 'apertium apy',
        check_command => "check_http_hostheader_port_url!apertium.svc.${::site}.wmnet!${port}!/listPairs",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/CX',
    }
}
