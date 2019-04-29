# === Define profile::trafficserver::nrpe_monitor_script
#
# Install the script specified in $title (or $checkname) under
# /usr/local/lib/nagios/plugins/, add a sudoers entry so that $sudo_user can
# execute the script, create a nrpe::monitor_service.
#
# [*sudo_user*]
#   User to execute this monitoring script as.
#
# [*checkname*]
#  Script name, defaulting to $title.
#
# [*args*]
#   Optional arguments to pass to the script.
#
define profile::trafficserver::nrpe_monitor_script(
    String $sudo_user,
    String $checkname = $title,
    String $args = '',
){
    $full_path = "/usr/local/lib/nagios/plugins/${checkname}"

    unless defined(File[$full_path]) {
        file { $full_path:
            ensure => present,
            source => "puppet:///modules/profile/trafficserver/${checkname}.sh",
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }
    }

    sudo::user { "nagios_trafficserver_${title}":
        user       => 'nagios',
        privileges => ["ALL = (${sudo_user}) NOPASSWD: ${full_path}"],
    }

    nrpe::monitor_service { $title:
        description  => $title,
        nrpe_command => "sudo -u ${sudo_user} ${full_path} ${args}",
        require      => File[$full_path],
    }
}
