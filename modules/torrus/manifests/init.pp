class torrus {

    include torrus::config,
        torrus::ddxfile,
        torrus::discovery,
        torrus::web,
        torrus::xml-generation,
        torrus::xmlconfig

    package { 'torrus-common':
        ensure => 'latest',
    }
}
