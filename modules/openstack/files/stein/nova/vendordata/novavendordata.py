#!/usr/bin/python3

# The rough outline for this code is derived from https://github.com/mikalstill/vendordata.git

import json
import sys
import jinja2

from webob import Response
from webob.dec import wsgify
from paste import httpserver
from paste.deploy import loadapp

from oslo_config import cfg
from oslo_log import log as logging


CONF = cfg.CONF
LOG = logging.getLogger(__name__)

cfg.CONF.register_group(
    cfg.OptGroup(
        name="vendordata_context",
        title="deployment-specific things we need for vendor data",
    )
)

cfg.CONF.register_opts(
    [
        cfg.StrOpt("instance_domain", default="incorrect.domain"),
        cfg.StrOpt("vendordata_file", default=""),
        cfg.StrOpt("listen_port", default="8888"),
    ],
    group="vendordata_context",
)


@wsgify
def application(req):
    if req.environ.get("HTTP_X_IDENTITY_STATUS") != "Confirmed":
        return Response("User is not authenticated", status=401)

    try:
        data = req.environ.get("wsgi.input").read()
        if not data:
            return Response("No data provided", status=500)

        # Get the data nova handed us for this request
        #
        # An example of this data:
        # {
        #     "hostname": "foo",
        #     "image-id": "75a74383-f276-4774-8074-8c4e3ff2ca64",
        #     "instance-id": "2ae914e9-f5ab-44ce-b2a2-dcf8373d899d",
        #     "metadata": {},
        #     "project-id": "039d104b7a5c4631b4ba6524d0b9e981",
        #     "user-data": null
        # }
        instance = json.loads(data)
        instance_domain = cfg.CONF["vendordata_context"].instance_domain

        if "hostname" not in instance:
            LOG.error("hostname not present in instance data.")
            return Response("Incomplete instance data, missing hostname", status=500)
        if "project-id" not in instance:
            LOG.error("project-id not present in instance data.")
            return Response("Incomplete instance data, missing project-id", status=500)

        fqdn = "%s.%s.%s" % (
            instance["hostname"],
            instance["project-id"],
            instance_domain,
        )

        vendordata_file = cfg.CONF["vendordata_context"].vendordata_file
        with open(vendordata_file) as file_:
            template = jinja2.Template(file_.read())

        outdata = template.render(instance=instance, fqdn=fqdn)

        return Response(json.dumps(outdata, indent=4, sort_keys=True))

    except Exception as e:
        return Response("Server error while processing request: %s" % e, status=500)


def app_factory(global_config, **local_config):
    return application


def main():
    logging.register_options(CONF)

    # Make keystonemiddleware emit debug logs
    extra_default_log_levels = ["keystonemiddleware=DEBUG"]
    logging.set_defaults(
        default_log_levels=(logging.get_default_log_levels() + extra_default_log_levels)
    )

    # Parse our config
    CONF(sys.argv[1:])

    # Set us up to log as well
    logging.setup(CONF, "vendordata")

    # Start the web server
    wsgi_app = loadapp("config:paste.ini", relative_to="/etc/novavendordata")

    listen_port = cfg.CONF["vendordata_context"].listen_port

    # Only listen locally. Every metadata server will have
    #  one of these services running alongside it.
    httpserver.serve(wsgi_app, host="127.0.0.1", port=listen_port)


if __name__ == "__main__":
    main()
