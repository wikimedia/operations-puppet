# Wiki Loves Monuments API server, RT#3221

class misc::wlm {
        system_role { "misc::wlm": description => "WLM API server" }

        include admins::roots,
                admins::dctech,
                admins::mortals,
                apaches::packages,
                mysql

        file {
                # WLM checkouts and data
                "/var/wlm":
                        owner => "root",
                        ensure => directory,git bash auto
                        mode => 0777;
                # WLM API dir
                "/var/www/api":
                        owner => root,
                        ensure => directory;
                # Symlink to api.php
                "/var/www/api/api.php":
                        owner => root,
                        mode => 0444,
                        ensure => "/var/wlm/erfgoed/api/api.php";
        }

        cron {
                update_from_toolserver:
                        hour => 4, # TS updates on the 3rd hour
                        command => "/var/wlm/update_from_toolserver.sh",
                        user => "root";
        }
}

