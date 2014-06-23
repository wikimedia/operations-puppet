# == Define zuul::configfile
#
# Crafts a Zuul configuration file
#
# === Parameters
#
# Required:
#
# **$name** Full path of the file to be created
# **$zuul_role** Either 'merger' or 'server'
#
# Optional:
#
# Parameters passed to file {}:
# **$owner** Default 'root'
# **$group** Default 'root'
# **$mode** Default '0444'
define zuul::configfile(
    $zuul_role,
    $owner = 'root',
    $group = 'root',
    $mode  = '0444',
) {
    file { $name:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('zuul/zuul.conf.erb'),
    }
}
