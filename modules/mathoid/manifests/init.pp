# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
# === Parameters
#
# [*png_generation*]
#   Enable PNG generation. This is done via shelling out to Java and temporary
#   files, so it might be insecure.
#
class mathoid($png_generation=false) {

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    if $png_generation {
        require_package('openjdk-7-jre-headless')
    }

    service::node { 'mathoid':
        port            => 10042,
        config          => {
            svg       => true,
            img       => true,
            png       => $png_generation,
            speakText => false,
        },
        healthcheck_url => '/_info',
        require         => Package['openjdk-7-jre-headless'],
    }
}
