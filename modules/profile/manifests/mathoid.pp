# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
class profile::mathoid {
    # NOTE: this is a temporary work-around for the CI to be able to install
    # development packages. In the future, we want to have more integration so as to
    # run tests as close to production as possible.
    #
    service::packages { 'mathoid':
        pkgs     => ['librsvg2-2'],
        dev_pkgs => ['librsvg2-dev'],
    }

    service::node { 'mathoid':
        port              => 10042,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
    }
}
