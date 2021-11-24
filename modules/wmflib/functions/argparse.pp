# @summary take a hash of key value parse and return an argument string
# @example
#  wmflib::argparse({hostname => 'foo.example.org', port => 8080, ssl => true}) =>
#   '--hostname foo.example.org --port 8080 --ssl'
#
function wmflib::argparse (
    Hash   $args,
    String $prefix = '',
) >> String {
    $args.reduce($prefix) |$memo, $value| {
        $args_str = $value[1] ? {
            Boolean => $value[1].bool2str(" --${value[0]}", ''),
            Array   => " --${value[0]} ${value[1].join(',').shell_escape}",
            # handle spaces, double quotes, etc.
            default => " --${value[0]} ${value[1].shell_escape}",
        }
        "${memo}${args_str}".strip
    }
}
