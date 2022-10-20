class dumps::web::enterprise(
    $is_primary_server = false,
    $dumps_web_server = undef,
    $user = undef,
    $group = undef,
    $miscdumpsdir = undef,
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

    file { '/srv/dumps/temp':
        ensure => 'directory',
        mode   => '0755',
        owner  => $user,
        group  => $group,
    }

    if $is_primary_server {
        $download_command = "/usr/bin/python3 ${script_path} --creds ${creds_path} --settings ${settings_path} --retries 2"
        systemd::timer::job { 'download_enterprise_htmldumps':
            ensure                  => present,
            description             => 'Twice monthly download of Wikimedia Enterprise HTML dumps',
            user                    => $user,
            monitoring_enabled      => false,
            send_mail               => true,
            send_mail_only_on_error => false,
            environment             => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command                 => $download_command,
            interval                => {'start' => 'OnCalendar', 'interval' => '*-*-1,20 8:30:0'},
            require                 => [ File[$script_path], File[$creds_path], File[$settings_path] ],
        }
    }

    if ($is_primary_server == false) {
        # rsync the downloaded files to secondary host, allowing the rsync to take a full day
        $rsync_command = "/usr/bin/rsync -a --bwlimit=160000 ${dumps_web_server}::data/xmldatadumps/public/other/enterprise_html/runs ${miscdumpsdir}/enterprise_html/"
        systemd::timer::job { 'rsync_enterprise_htmldumps':
            ensure             => present,
            description        => 'Twice monthly rsync after download of Wikimedia Enterprise HTML dumps',
            user               => root,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => $rsync_command,
            interval           => {'start' => 'OnCalendar', 'interval' => '*-*-2,21 8:30:0'},
            require            => [ File[$script_path], File[$creds_path], File[$settings_path] ],
        }
    }
}
