# @summary take a hash of key value parse and return an argument string
# @example
#  wmflib::argparse({hostname => 'foo.example.org', port => 8080, ssl => true}) =>
#   '--hostname foo.example.org --port 8080 --ssl'
# @param args the arguments to parse
# @param prefix the prefix to put at the start of the command e.g. /usr/bin/binary
# @param separator use to separator argument switches from the value
#
function wmflib::argparse (
    Hash[String[2], Variant[Boolean, String, Numeric, Array[Variant[String, Numeric]]]] $args,
    String                                                                              $prefix    = '',
    String[1,1]                                                                         $separator = ' ',
) >> String {
    $args.reduce($prefix) |$memo, $value| {
        $args_str = $value[1] ? {
            Boolean => $value[1].bool2str(" --${value[0]}", ''),
            Array   => " --${value[0]}${separator}${value[1].join(',').shell_escape}",
            # handle spaces, double quotes, etc.
            default => " --${value[0]}${separator}${value[1].shell_escape}",
        }
        "${memo}${args_str}".strip
    }
}
