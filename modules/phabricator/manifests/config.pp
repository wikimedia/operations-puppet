define phabricator::config (
    $value,
) {
    exec { "phabricator-config-${name}" :
        command => "./bin/config set ${name} ${value}",
        cwd => $phabricator::phabdir,
        user => $phabricator::user,
    }
}
