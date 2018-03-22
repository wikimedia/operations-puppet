class standard::mail::sender {
    class { '::exim4':
        queuerunner => 'queueonly',
        config      => template("standard/mail/exim4.minimal.${::realm}.erb"),
    }

    if os_version('debian >= jessie') {
        base::service_auto_restart { 'exim4': }
    }
}
