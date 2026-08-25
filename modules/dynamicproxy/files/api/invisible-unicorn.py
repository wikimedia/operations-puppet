#!/usr/bin/env python3
# ^ above line exists purely to make Jenkins test this using Python 3
#
#   Copyright 2013 Yuvi Panda <yuvipanda@gmail.com>
#   Copyright 2021 Taavi Väänänen <hi@taavi.wtf>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

"""Simple HTTP API for controlling a dynamic HTTP Proxy.

Stores canonical information about the proxying rules in a database."""
import flask
import ipaddress
import json
import mwopenstackclients
import re
from urllib.parse import urlparse

from designateclient.v2 import client as designateclient
from flask_keystone import FlaskKeystone
from flask_oslolog import OsloLog
from flask_sqlalchemy import SQLAlchemy
from oslo_config import cfg
from oslo_context import context
from oslo_policy import policy
from werkzeug.exceptions import HTTPException

cfgGroup = cfg.OptGroup("dynamicproxy")
opts = [
    cfg.StrOpt("dns_updater_keystone_api_url"),
    cfg.StrOpt("dns_updater_username"),
    cfg.StrOpt("dns_updater_password", secret=True),
    cfg.StrOpt("dns_updater_project"),
    cfg.StrOpt("zones_json_file"),
    cfg.StrOpt("proxy_dns_ipv4"),
    cfg.StrOpt("proxy_dns_ipv6"),
    cfg.StrOpt("sqlalchemy_uri", secret=True),
]

key = FlaskKeystone()
log = OsloLog()

cfg.CONF.register_group(cfgGroup)
cfg.CONF.register_opts(opts, group=cfgGroup)

cfg.CONF(default_config_files=["/etc/dynamicproxy-api/config.ini"])

enforcer = policy.Enforcer(cfg.CONF)
enforcer.register_defaults(
    [
        policy.RuleDefault("admin", "role:admin"),
        policy.RuleDefault("admin_or_member", "rule:admin or role:member or role:proxyadmin"),
        policy.RuleDefault("proxy:zones:index", ""),
        policy.RuleDefault("proxy:zones:use_deprecated", "rule:admin"),
        policy.RuleDefault("proxy:index", ""),
        policy.RuleDefault("proxy:view", ""),
        policy.RuleDefault("proxy:create", "rule:admin_or_member"),
        policy.RuleDefault("proxy:update", "rule:admin_or_member"),
        policy.RuleDefault("proxy:delete", "rule:admin_or_member"),
    ]
)

app = flask.Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = cfg.CONF.dynamicproxy.sqlalchemy_uri

db = SQLAlchemy(
    app,
    engine_options={
        "pool_recycle": 1800,
        "pool_pre_ping": True,
    },
)

key.init_app(app)
log.init_app(app)


class Project(db.Model):
    """
    Represents a Keystone project.
    Primary unit of access control.
    """

    id = db.Column(db.Integer, primary_key=True)
    openstack_id = db.Column(db.String(256), unique=True)


class Route(db.Model):
    """Represents a route that has one matching rule and a backend.

    Currently the only supported rule is to match entire domains"""

    id = db.Column(db.Integer, primary_key=True)
    domain = db.Column(db.String(256), unique=True)
    project_id = db.Column(db.Integer, db.ForeignKey("project.id"))
    project = db.relationship("Project", backref=db.backref("routes", lazy="dynamic"))
    backend_url = db.Column(db.String(256))


class Dns:
    """Deals with any DNS writes."""

    RECORD_DESCRIPTION = "managed by Cloud VPS web proxy service"

    def __init__(
        self,
        zones: dict,
        target_ipv4: str,
        target_ipv6: str,
        clients: mwopenstackclients.Clients,
    ):
        self.zones = zones
        self.target_ipv4 = target_ipv4
        self.target_ipv6 = target_ipv6
        self.clients = clients

    def designateclient(self, project) -> designateclient.Client:
        return designateclient.Client(session=self.clients.session(project))

    def get_zone(self, project: str, hostname: str, *, ignore_deprecated: bool = False):
        """Determines the Keystone project and DNS zone to use for a particular hostname."""
        if hostname[-1] != ".":
            hostname += "."

        zone_name = None
        if hostname in self.zones:
            zone_name = hostname
        elif hostname[hostname.index(".") + 1 :] in self.zones:  # noqa: E203
            zone_name = hostname[hostname.index(".") + 1 :]  # noqa: E203
        else:
            log.logger.info(
                "Did not find zone for hostname %s (supported zones %s)",
                hostname,
                ", ".join(self.zones.keys()),
            )
            return None

        if self.zones[zone_name].get("deprecated", False) and not ignore_deprecated:
            enforce_policy("proxy:zones:use_deprecated", project)
        if self.zones[zone_name]["project"] != project and not self.zones[
            zone_name
        ].get("shared", False):
            log.logger.warning(
                "Rejecting project %s from using non-shared zone %s in %s",
                project,
                zone_name,
                self.zones[zone_name]["project"],
            )
            return None
        if hostname.startswith("*.") and self.zones[zone_name].get("shared", False):
            log.logger.warning(
                "Rejecting project %s from using wildcard in shared zone %s",
                project,
                zone_name,
            )
            return None
        if hostname == zone_name and not self.zones[zone_name].get("apex", False):
            log.logger.warning(
                "Rejecting project %s from using apex in zone %s",
                project,
                zone_name,
            )
            return None

        for zone in self.designateclient(project).zones.list():
            # we don't have multi-level wildcard certs
            if zone["name"] == hostname:
                return (hostname, project, zone["id"])

        # TODO: check for conflicting other projects' zones?

        return (
            hostname,
            self.zones[zone_name]["project"],
            self.zones[zone_name].get("id"),
        )

    def can_use_hostname(self, project: str, hostname: str) -> bool:
        """Checks if the given project can use the given hostname."""
        zone = self.get_zone(project, hostname)
        if zone is None:
            return False

        hostname, project, zone_id = zone
        if zone_id:
            client = self.designateclient(project)

            existing_records = [
                record
                for record in client.recordsets.list(
                    zone_id, criterion={"name": hostname}
                )
                if record["type"] in ("A", "AAAA")
            ]
            if len(existing_records) != 0:
                log.logger.info(
                    "Rejecting can_use_hostname (%s %s), found existing records: %s",
                    project,
                    hostname,
                    ", ".join([record["name"] for record in existing_records]),
                )

                return False

        return True

    def add_records_for(self, project: str, hostname: str):
        hostname, project, zone_id = self.get_zone(project, hostname)
        if not zone_id:
            return

        client = self.designateclient(project)

        if not client.recordsets.list(
            zone_id, criterion={"name": hostname, "type": "A"}
        ):
            client.recordsets.create(
                zone_id,
                hostname,
                "A",
                [self.target_ipv4],
                description=Dns.RECORD_DESCRIPTION,
            )

        if not client.recordsets.list(
            zone_id, criterion={"name": hostname, "type": "AAAA"}
        ):
            client.recordsets.create(
                zone_id,
                hostname,
                "AAAA", [self.target_ipv6],
                description=Dns.RECORD_DESCRIPTION,
            )

    def delete_records_for(self, project: str, hostname: str):
        hostname, project, zone_id = self.get_zone(project, hostname, ignore_deprecated=True)
        if not zone_id:
            return

        client = self.designateclient(project)

        for record in client.recordsets.list(zone_id, criterion={"name": hostname}):
            if record["type"] not in ("A", "AAAA"):
                continue
            client.recordsets.delete(zone_id, record["id"])


with open(cfg.CONF.dynamicproxy.zones_json_file, "r") as f:
    zones = json.load(f)

dns = Dns(
    zones,
    cfg.CONF.dynamicproxy.proxy_dns_ipv4,
    cfg.CONF.dynamicproxy.proxy_dns_ipv6,
    mwopenstackclients.Clients(
        username=cfg.CONF.dynamicproxy.dns_updater_username,
        password=cfg.CONF.dynamicproxy.dns_updater_password,
        project=cfg.CONF.dynamicproxy.dns_updater_project,
        url=cfg.CONF.dynamicproxy.dns_updater_keystone_api_url,
    ),
)
osclients = mwopenstackclients.Clients(oscloud="novaobserver")


class Forbidden(HTTPException):
    code = 403
    description = "Forbidden."


def is_valid_domain(hostname):
    """
    Credit for this function goes to Tim Pietzcker and other StackOverflow contributors
    See https://stackoverflow.com/a/2532344
    """
    if "." not in hostname:
        return False
    if len(hostname) > 255:
        return False
    if hostname[-1] == ".":
        # strip exactly one dot from the right, if present
        hostname = hostname[:-1]
    allowed = re.compile("(?!-)[A-Z\\d-]{1,63}(?<!-)$", re.IGNORECASE)
    parts_for_validation = hostname.split(".")

    # Allow a wildcard at the very start. There's separate policy checking when they can
    # really be used.
    if parts_for_validation[0] == "*":
        parts_for_validation = parts_for_validation[1:]

    return all(allowed.match(x) for x in parts_for_validation)


def environify_header_name(name):
    return "HTTP_{}".format(name.upper().replace("-", "_"))


def enforce_policy(rule, project_id):
    # headers in a specific format that oslo.context wants
    headers = {
        environify_header_name(name): value
        for name, value in flask.request.headers.items()
    }
    ctx = context.RequestContext.from_environ(headers)

    # if the project in the url is for a different project than what
    # the keystone token is, error out early.
    if ctx.project_id != project_id:
        log.logger.warning(
            "Encountered project id %s but keystone token was for project %s",
            project_id,
            ctx.project_id,
        )
        raise Forbidden("Invalid project id.")

    log.logger.info(
        "Enforcing policy %s for user %s (%s) and project %s",
        rule,
        ctx.user_id,
        ", ".join(ctx.roles),
        ctx.project_id,
    )

    enforcer.authorize(
        rule,
        {"project_id": project_id},
        ctx,
        do_raise=True,
        exc=Forbidden,
    )


@app.route("/v1/<project_id>/zones", methods=["GET"])
def list_zones(project_id):
    enforce_policy("proxy:zones:index", project_id)

    try:
        enforce_policy("proxy:zones:use_deprecated", project_id)
    except Forbidden:
        use_deprecated = False
    else:
        use_deprecated = True

    data = {
        zone.rstrip("."): {
            "deprecated": details.get("deprecated", False),
            "default": details.get("default", False),
            "shared": details.get("shared", False),
            "apex": details.get("apex", False),
        }
        for zone, details in zones.items()
        if (
            (use_deprecated or not details.get("deprecated", False))
            and (details["project"] == project_id or details.get("shared", False))
        )
    }

    return flask.jsonify(data)


@app.route("/v1/<project_id>/mapping", methods=["GET"])
def all_mappings(project_id):
    enforce_policy("proxy:index", project_id)

    project = Project.query.filter_by(openstack_id=project_id).first()
    data = {"routes": []}

    if project:
        for route in project.routes:
            data["routes"].append(
                {
                    "domain": route.domain,
                    "backend": route.backend_url,
                    # for backwards compatibility: (T429960)
                    "backends": [route.backend_url],
                }
            )

    return flask.jsonify(**data)


@app.route("/v1/<project_id>/scrub_mapping", methods=["PUT"])
def scrub_mappings(project_id):
    """For the specified project, check each existing mapping and delete
    any that don't correspond to an existing nova VM. This is called
    by designate in response to a VM deletion."""
    enforce_policy("proxy:delete", project_id)

    # Gather all assigned IPs in the project
    instances = osclients.allinstances(project_id)
    valid_ips = []
    for instance in instances:
        for network in instance.addresses:
            valid_ips.extend(
                [
                    str(ipaddress.ip_address(address["addr"]))
                    for address in instance.addresses[network]
                    if instance.status != "DELETED" and instance.status != "DELETING"
                ]
            )

    project = Project.query.filter_by(openstack_id=project_id).first()
    if not project:
        return "Project not found", 404

    for route in project.routes:
        backend_host = urlparse(route.backend_url).hostname

        try:
            # Validates the address and converts it into a single format
            # to compare as strings.
            backend_ip = str(ipaddress.ip_address(backend_host))
        except ValueError:
            # There are some weird proxies that refer to service names
            # instead of IPs. Don't delete them.
            continue

        if backend_ip in valid_ips:
            continue

        log.logger.info("Scrubbing %s from project %s", route.domain, project_id)
        dns.delete_records_for(project_id, route.domain)
        db.session.delete(route)
        db.session.commit()

    return "OK", 200


@app.route("/v1/<project_id>/mapping", methods=["PUT"])
def create_mapping(project_id):
    data = flask.request.get_json(True)

    if "domain" not in data or not isinstance(data["domain"], str):
        return flask.jsonify({"error": "'domain' is missing or invalid"}), 400

    # for backwards compatibility: (T429960)
    if "backends" in data:
        if "backend" in data:
            return flask.jsonify({"error": "'backend' and 'backends' cannot be both set"}), 400
        if not isinstance(data["backends"], list):
            return flask.jsonify({"error": "'backend' is invalid"}), 400
        if len(data["backends"]) != 1:
            return flask.jsonify({"error": "Exactly one backend must be provided"}), 400
        data["backend"] = data["backends"][0]

    if "backend" not in data or not isinstance(data["backend"], str):
        return flask.jsonify({"error": "'backend' is missing or invalid"}), 400

    domain = data["domain"]
    if not is_valid_domain(domain):
        return "Invalid domain", 400

    backend_url = data["backend"]

    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        project = Project(openstack_id=project_id)
        db.session.add(project)

    route = Route.query.filter_by(domain=domain).first()
    if route is not None:
        return flask.jsonify({"error": "A proxy with this domain already exists"}), 400

    enforce_policy("proxy:create", project_id)
    if not dns.can_use_hostname(project_id, domain):
        return flask.jsonify({"error": f"Can't use domain {domain}"}), 403

    dns.add_records_for(project_id, domain)

    route = Route(
        domain=domain,
        project=project,
        backend_url=backend_url,
    )

    db.session.add(route)
    db.session.commit()

    return "", 200


@app.route("/v1/<project_id>/mapping/<domain>", methods=["DELETE"])
def delete_mapping(project_id, domain):
    enforce_policy("proxy:delete", project_id)

    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        return "No such domain", 400

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 404

    dns.delete_records_for(project_id, domain)

    db.session.delete(route)
    db.session.commit()

    return "deleted", 200


@app.route("/v1/<project_id>/mapping/<domain>", methods=["GET"])
def get_mapping(project_id, domain):
    enforce_policy("proxy:view", project_id)

    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        return "No such domain", 404

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 404

    data = {
        "domain": route.domain,
        "backend": route.backend_url,
        # for backwards compatibility: (T429960)
        "backends": [route.backend_url],
    }

    return flask.jsonify(**data)


@app.route("/v1/<project_id>/mapping/<domain>", methods=["POST"])
def update_mapping(project_id, domain):
    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        return "No such domain", 404

    enforce_policy("proxy:update", project_id)

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 404

    data = flask.request.get_json(True)

    # If a domain is specified in the background, validate that it
    # is not changing. We no longer support renaming an existing proxy,
    # so there's no real need to require clients to pass a domain in the
    # body, but
    #  * we used to support that, and
    #  * for client libraries (like go-cloudvps), it is simpler to pass the same
    #    body structure for requests to create and update proxies,
    # so we support passing one and throw an error if the request is trying to
    # rename the proxy to avoid confusion.
    if data.get("domain") and route.domain != data["domain"]:
        return flask.jsonify({"error": "Can't rename a proxy"}), 400

    # for backwards compatibility: (T429960)
    if "backends" in data:
        if "backend" in data:
            return flask.jsonify({"error": "'backend' and 'backends' cannot be both set"}), 400
        if not isinstance(data["backends"], list):
            return flask.jsonify({"error": "'backend' is invalid"}), 400
        if len(data["backends"]) != 1:
            return flask.jsonify({"error": "Exactly one backend must be provided"}), 400
        data["backend"] = data["backends"][0]

    if "backend" not in data or not isinstance(data["backend"], str):
        return flask.jsonify({"error": "'backend' is missing or invalid"}), 400

    route.backend_url = data["backend"]
    db.session.add(route)
    db.session.commit()

    return "OK", 200


if __name__ == "__main__":
    app.run(debug=True)
