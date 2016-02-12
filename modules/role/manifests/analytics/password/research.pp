# == Class role::analytics::password::research
# Install the researcher MySQL username and password
# into a file and make it readable by analytics-privatedata-users
#
class role::analytics::password::research {
    include passwords::mysql::research

    mysql::config::client { 'analytics-research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'analytics-privatedata-users',
        mode  => '0440',
    }
}
