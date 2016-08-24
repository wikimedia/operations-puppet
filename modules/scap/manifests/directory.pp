# Helper define to be used only in scap::source
# Creates a directory with default params, only if it wasn't created before
define scap::directory($params) {
    $myparams = merge({ensure => directory}, $params)
    if !defined(File[$title]) {
        $fullargs = { "${title}" => $myparams }
        create_resource(file, $fullargs)
    }
}
