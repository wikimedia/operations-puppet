#!/bin/bash

# This file is managed by Puppet.

exec sed -ne 's/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+ - - \(\[[^]]\+\]\) "\(GET\) \/\([^\/]\+\)\/.* \(HTTP\/1.1\)" \([0-9]\{3\}\) \([0-9]\+\) .*$/127.0.0.1 - - \1 "\2 \/\3 \4" \5 \6/p;' /var/log/apache2/access.log
