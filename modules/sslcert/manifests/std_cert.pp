# == Define: sslcert::std_cert
#
# This is a wrapper for sslcert::certificate which defines a different set of
# defaults for "normal" certificate usage.  There are no parameters aside from
# "ensure", the resource title is used to source the private and public keys
# from our standard paths, and all other parameters are defaulted at the
# sslcert::certificate level.
#
# This makes array usage much easier for the common case, as in:
# $foo = [ 'bar.org', 'baz.org' ]
# sslcert::std_cert { $foo: }
#

define sslcert::std_cert($ensure=present) {
    sslcert::certificate { $title:
        ensure  => $ensure,
        source  => "puppet:///files/ssl/${title}.crt",
        private => "puppet:///private/ssl/${title}.key",
    }
}
