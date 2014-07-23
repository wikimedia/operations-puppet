# This define installs an alternative in the alternatives database.
#
#
#
define alternatives::install (
    $link,
    $path,
    $priority = 1,
    $name     = $title,
    $config   = false
) {

    if $name !~ /^[\w\-_]+$/ { fail("Invalid alternative name '${name}'") }
    if $priority  !~ /^\d+$/      { fail('"priority" must be integer') }

    exec { "alternatives_install_${title}":
        command => "/usr/bin/update-alternatives --install ${link} ${name} ${path} ${priorit}",
        unless  => "/usr/bin/update-alternatives --query ${name} | /bin/grep -q '^Alternative: ${path}\$'"
    }

    if $config {
        alternatives::config{ $name:
            path => $path
        }
    }

}
