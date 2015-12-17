# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
# === Parameters
#
# [*svg_generation*]
#   Enable SVG generation
# [*img_generation*]
#   Enable IMG generation.
# [*png_generation*]
#   Enable PNG generation. This is done via shelling out to Java and temporary
#   files, so it might be insecure.
# [*speakText_generation*]
#   Enable speakText generation.
# [*textvcinfo_generation*]
#   Enable texvcinfo generation. Default: true
#
class mathoid(
    $svg_generation=true,
    $img_generation=true,
    $png_generation=false,
    $speakText_generation=false,
    $texvcinfo_generation=true,
) {

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    if $png_generation {
        require_package('openjdk-7-jre-headless')
    }

    service::node { 'mathoid':
        port            => 10042,
        no_workers      => 50,
        config          => {
            svg       => $svg_generation,
            img       => $img_generation,
            png       => $png_generation,
            speakText => $speakText_generation,
            texvcinfo => $texvcinfo_generation,
        },
        healthcheck_url => '',
        has_spec        => true,
    }
}
