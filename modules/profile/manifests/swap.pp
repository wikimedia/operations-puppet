# == Class profile::swap
# SWAP - Simple Web Analytics Platform
#
class profile::swap(
    $allowed_posix_groups = hiera('admin::groups', undef),
    $default_jupyter      = hiera('profile::swap::default_jupyter', 'jupyterlab')
) {
    if $::realm == 'production' {
        $web_proxy = "http://webproxy.${::site}.wmnet:8080"

        statistics::mysql_credentials { 'research':
            group => 'researchers',
        }
        if !$allowed_posix_groups {
            $_allowed_posix_groups = ['wikidev']
        }
    }
    else {
        $web_proxy = undef
        if !$allowed_posix_groups {
            $_allowed_posix_groups = ["project-${::labsproject}"]
        }
    }

    class { 'swap':
        allowed_posix_groups => $_allowed_posix_groups,
        web_proxy            => $web_proxy,
    }

    class { '::statistics::packages': }
}
