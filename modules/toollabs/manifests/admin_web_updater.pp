# This is responsible for https://tools.wmflabs.org/
class toollabs::admin_web_updater(
    $active
) {
    if $active {

        # Deploy and update root web.
        git::clone { 'labs/toollabs':
            ensure    => latest,
            directory => '/data/project/admin/toollabs',
            owner     => "${::labsproject}.admin",
            group     => "${::labsproject}.admin",
            mode      => '2755',
        }

        file { '/data/project/admin/public_html':
            ensure  => link,
            force   => true,
            target  => 'toollabs/www',
            require => Git::Clone['labs/toollabs'],
        }
    }
}
