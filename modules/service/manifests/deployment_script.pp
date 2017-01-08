# === Define service::deployment_script
#
# Creates a script that should make deploying a config+code change easier.
#
define service::deployment_script(
    $monitor_url,
    $release_dir="/srv/deployment/${title}/deploy",
    $provider='git',
    $has_autorestart=false,
){
    $service = $title
    file { "/usr/local/bin/${service}-deploy":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('service/deployment_script.sh.erb'),
    }

}
