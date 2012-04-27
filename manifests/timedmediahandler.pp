# Install TimedMediaHandler dependencies and configuration

class timedmediahandler::ppa {
    apt::pparepo {
        "timedmediahandler": 
            repo_string => "j/timedmediahandler",
            apt_key => "01975EF3",
            dist => "lucid",
            ensure => "present"
    }
    package {
        ["ffmpeg"]:
            ensure => latest,
            require => Apt::Pparepo["timedmediahandler"];
    }
}

class timedmediahandler::web {
    include webserver::php5

    if ( $lsbdistcodename == "lucid" ) {
        include timedmediahandler::ppa
    }
    package {
        [ "php-pear",
          "imagemagick",
          "ffmpeg"
        ]:
        ensure => latest,
        notify => Service["apache2"],
        require => Exec[add-mimetype-webm];
    }
    exec {
        add-mimetype-webm:
            unless => "/bin/grep 'video/webm' /etc/mime.types",
            command => "/bin/echo 'video/webm                                      webm' >> /etc/mime.types";
    }
}
