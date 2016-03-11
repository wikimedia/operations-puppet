# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
# === Parameters
#
# [*svg_generation*]
#   Enable SVG generation. Default: true
# [*img_generation*]
#   Enable IMG generation. Default: true
# [*png_generation*]
#   Enable PNG generation, accomplished via a librsvg2 node binding. Default:
#   true
# [*speakText_generation*]
#   Enable speakText generation. Default: false
# [*textvcinfo_generation*]
#   Enable texvcinfo generation. Default: true
# [*render_no_check*]
#   Whether not to perform input checks on renders. Default: true
#
class mathoid(
    $svg_generation=true,
    $img_generation=true,
    $png_generation=true,
    $speakText_generation=false,
    $texvcinfo_generation=true,
    $render_no_check=true,
) {

    require ::mathoid::packages

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
    }
}
