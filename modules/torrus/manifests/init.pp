class torrus {

    include torrus::config,
        torrus::ddxfile,
        torrus::discovery,
        torrus::web,
        torrus::xml-generation,
        torrus::xmlconfig

    system::role { 'torrus': description => 'Torrus' }

    package { 'torrus-common':
        ensure => latest,
    }
}
