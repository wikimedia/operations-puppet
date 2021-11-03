class dumps::web::enterprise {
    file { '/usr/local/bin/wm_enterprise_downloader.py':
        ensure => 'present',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/wm_enterprise_downloader.py',
    }

    file { '/etc/dumps/wm_enterprise_creds':
        ensure  => 'present',
        mode    => '0640',
        owner   => 'root',
        group   => 'root',
        content => secret('dumps/wm_enterprise_creds'),
    }

    # the systemd timer to run the content pull and rsync will go here later.
}
