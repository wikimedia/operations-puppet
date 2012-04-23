# Install TimedMediaHandler dependencies and configuration

class timedmediahandler::web {
    include webserver::php5

    if ( $lsbdistcodename == "lucid" ) {
        apt::pparepo {
            "timedmediahandler": repo_string => "j/timedmediahandler",
                                 apt_key => "01975EF3",
                                 dist => "lucid",
                                 ensure => "present"
        }
        package {
            [ "php-pear",
              "imagemagick",
              "ffmpeg"
            ]:
            ensure => latest,
            Exec[add-mimetype-webm] ],
            notify => Service["apache2"],
            require => Apt::Pparepo["timedmediahandler"];
        }
    }
    exec {
        add-mimetype-webm:
            unless => "/bin/grep 'video/webm' /etc/mime.types",
            command => "/bin/echo 'video/webm                                      webm' >> /etc/mime.types";
    }
}
