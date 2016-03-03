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
# [*render_no_check*]
#   Whether not to perform input checks on renders. Default: true
#
class mathoid(
    $svg_generation=true,
    $img_generation=true,
    $png_generation=false,
    $speakText_generation=false,
    $texvcinfo_generation=true,
    $render_no_check=true,
) {

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    service::packages { 'mathoid':
        pkgs     => ['librsvg2-2'],
        dev_pkgs => ['librsvg2-dev'],
    }

    service::node { 'mathoid':
        port            => 10042,
        config          => {
            svg       => $svg_generation,
            img       => $img_generation,
            png       => $png_generation,
            speech_on => $speakText_generation,
            texvcinfo => $texvcinfo_generation,
            no_check  => $render_no_check,
        },
        healthcheck_url => '',
        has_spec        => true,
        require         => Service::Packages['mathoid'],
    }
}
