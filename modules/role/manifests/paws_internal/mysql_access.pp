class role::paws_internal::mysql_access {
    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }
}
