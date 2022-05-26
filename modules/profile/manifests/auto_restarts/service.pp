# == Define profile::auto_restarts::service
#
# This define can be used to add an automatic restart for a stateless service.
# wmf-auto-restart checks whether any dependent library has been refreshed and
# if that's the case, a restart is triggered. The restarts are spread out over
# the course of the day via fqdn_rand().
#
define profile::auto_restarts::service(
    Wmflib::Ensure $ensure  = present,
) {
    include profile::auto_restarts

    $hour = fqdn_rand(23, "${title}_auto_restart")
    $minute = fqdn_rand(59, "${title}_auto_restart")
    systemd::timer::job { "wmf_auto_restart_${title}":
        ensure      => $ensure,
        user        => 'root',
        description => "Auto restart job: ${title}",
        command     => "/usr/local/sbin/wmf-auto-restart -s ${title}",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "Mon,Tue,Wed,Thu,Fri *-*-* ${hour}:${minute}:00",
        },
        require     => File['/usr/local/sbin/wmf-auto-restart'],
    }

    if $profile::auto_restarts::with_debdeploy {
        # The include here and the check for ensure is really nuts and bolts
        # to ensure this code path works with rspec tests
        include profile::debdeploy::client
        if $profile::debdeploy::client::ensure == 'present' {
            file_line { "auto_restart_file_presence_${title}":
                ensure  => $ensure,
                path    => '/etc/debdeploy-client/autorestarts.conf',
                line    => $title,
                require => File['/etc/debdeploy-client/autorestarts.conf'],
            }
        }
    }
}
