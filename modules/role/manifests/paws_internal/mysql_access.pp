# = Class role::paws_internal::mysql_access
# Setup MySQL access to research dbs from paws_internal
class role::paws_internal::mysql_access {
    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }
}
