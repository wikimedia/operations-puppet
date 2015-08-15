define service::deployment_script(
    $monitor_url,
    $release_dir="/srv/deployment/${title}/deploy",
    $provider='git',
){
    $service = $title
    file { "/usr/local/bin/${service}-release":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('service/release_script.sh.erb')
    }

}
