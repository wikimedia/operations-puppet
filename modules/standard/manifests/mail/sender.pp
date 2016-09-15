class standard::mail::sender {
    class { 'exim4':
        queuerunner => 'queueonly',
        config      => template("standard/mail/exim4.minimal.${::realm}.erb"),
    }
}
