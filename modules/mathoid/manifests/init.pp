# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
class mathoid {

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    service::node { 'mathoid':
        port            => 10042,
        config          => '{}',
        healthcheck_url => '/',
    }
}
