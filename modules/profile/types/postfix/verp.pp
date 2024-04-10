# SPDX-License-Identifier: Apache-2.0
type Profile::Postfix::Verp = Struct[{
    post_connect_server => Stdlib::Host,
    bounce_post_url     => Stdlib::HTTPUrl,
}]
