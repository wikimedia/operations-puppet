# = Class: programdashboard::app
#
# The Program Dashboard Rails application.
#
# === Parameters
#
# [*dependencies*]
#   Array of packaged dependencies to be installed.
#
# [*directory*]
#   Target deployment directory.
#
# [*environment*]
#   Rails/Rack environment to specify when running the application.
#
# [*owner*]
#   Owner of the target deployment directory.
#
# [*group*]
#   Group owner of the deployment directory.
#
# [*deployer_keys*]
#   SSH keys to authorize for the deployment owner. When used in Labs, deploy
#   access can be granted by redefining this in Hiera:<project>.
#
class programdashboard::app(
    $dependencies,
    $directory,
    $environment,
    $owner,
    $group,
    $deployer_keys,
) {
    require programdashboard

    include apt
    include apache
    include apache::mod::passenger

    require_package($dependencies)

    group { $group:
        ensure => present,
    }

    user { $owner:
        ensure => present,
        gid    => $group,
    }

    file { $directory:
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0750',
    }

    $server_name = $::programdashboard::server_name
    $server_admin = $::programdashboard::server_admin

    apache::site { 'program-dashboard':
        content => template('programdashboard/apache.conf.erb'),
        require => File[$directory],
    }

    # Authorize direct SSH access as the deployment user to deployers
    ssh::userkey { $owner:
        content => join($deployer_keys, "\n"),
    }

    security::access::config { 'programdashboard-allow-deployers':
        content  => "+ : ${owner} : ALL\n",
        priority => 51,
    }
}
