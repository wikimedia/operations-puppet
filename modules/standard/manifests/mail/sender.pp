class standard::mail::sender {
    class { 'exim4':
        queuerunner => 'queueonly',
        config      => template("mail/exim4.minimal.${::realm}.erb"),
    }
}
