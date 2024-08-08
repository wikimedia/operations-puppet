# === Define service::deployment_script
#
# Creates a script that should make deploying a config+code change easier.
#
define service::deployment_script(
    Stdlib::HTTPUrl  $monitor_url,
    Stdlib::Unixpath $release_dir     = "/srv/deployment/${title}/deploy",
    String           $provider        = 'git',
    Boolean          $has_autorestart = false,
    Wmflib::Ensure   $ensure          = present,
){
    $service = $title
    file { "/usr/local/bin/${service}-deploy":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('service/deployment_script.sh.erb')
    }

}
