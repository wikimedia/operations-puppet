class dumps::web::enterprise(
    $user = undef,
    $group = undef,
){
    $script_path = '/usr/local/bin/wm_enterprise_downloader.py'
    file { $script_path:
        ensure => 'present',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/wm_enterprise_downloader.py',
    }

    $creds_path = '/etc/dumps/wm_enterprise_creds'
    file { $creds_path:
        ensure  => 'present',
        mode    => '0640',
        owner   => $user,
        group   => $group,
        content => secret('dumps/wm_enterprise_creds'),
    }

    $settings_path = '/etc/dumps/wm_enterprise_settings'
    file { $settings_path:
        ensure => 'present',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/wm_enterprise_settings',
    }
}
