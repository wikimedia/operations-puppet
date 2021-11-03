class dumps::web::enterprise {
    file { '/usr/local/bin/wm_enterprise_downloader.py':
        ensure => 'present',
        path   => '/usr/local/bin/wm_enterprise_downloader.py',
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/wm_enterprise_downloader.py',
    }

    # the systemd timer to run the content pull will go here later.
}
