# SPDX-License-Identifier: Apache-2.0
type Profile::Postfix::Mail_aliases = Struct[{
    path    => Stdlib::Unixpath,
    rcpt    => Stdlib::Email,
    subject => String[1],
}]
