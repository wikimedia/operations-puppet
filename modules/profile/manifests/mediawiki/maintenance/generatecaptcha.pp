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

    $generatecaptcha_command = $::_role ? {
        'deployment_server/kubernetes' => '/usr/local/bin/mwscript extensions/ConfirmEdit/maintenance/GenerateFancyCaptchas.php enwiki --wordlist=/etc/fancycaptcha/words --font=/usr/share/fonts/truetype/freefont/FreeMonoBoldOblique.ttf --badwordlist=/etc/fancycaptcha/badwords --fill=10000 --delete --threads=4',
        default                        => '/usr/local/bin/captchaloop',
    }

    profile::mediawiki::periodic_job { 'generatecaptcha':
        command                 => $generatecaptcha_command,
        interval                => 'Mon 01:00',
        cron_schedule           => '00 01 * * MON',
        kubernetes              => true,
        team                    => 'security',
        script_label            => 'GenerateFancyCaptchas.php',
        description             => 'Generate new captchas weekly',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1209600, # 2 weeks
    }
}
