class profile::mediawiki::maintenance::generatecaptcha(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    if $::_role == 'deployment_server/kubernetes' {
        $fancycaptcha = {
            'mw' => {
                'fancycaptcha' => {
                    'badwords' => secret('fancycaptcha/badwords'),
                    'words' => secret('fancycaptcha/words')
                }
            }
        }

        file { "${helmfile_defaults_dir}/mediawiki/fancycaptcha.yaml":
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => $fancycaptcha.to_yaml,
        }

        # TODO: Remove old file path absent resources.
        file { '/etc/fancycaptcha':
            ensure => 'absent',
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }

        file { '/etc/fancycaptcha/words':
            ensure  => 'absent',
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => secret('fancycaptcha/words');
        }

        file { '/etc/fancycaptcha/badwords':
            ensure  => 'absent',
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => secret('fancycaptcha/badwords');
        }

        file { '/usr/local/bin/captchaloop':
            ensure => 'absent',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/mediawiki/captchaloop',
        }
    } else {
        file { '/etc/fancycaptcha':
            ensure => 'directory',
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }

        file { '/etc/fancycaptcha/words':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => secret('fancycaptcha/words');
        }

        file { '/etc/fancycaptcha/badwords':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => secret('fancycaptcha/badwords');
        }

        file { '/usr/local/bin/captchaloop':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/mediawiki/captchaloop',
        }
    }

    profile::mediawiki::periodic_job { 'generatecaptcha':
        command  => '/usr/local/bin/captchaloop',
        interval => 'Mon 01:00',
    }
}
