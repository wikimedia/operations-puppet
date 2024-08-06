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

Stores canonical information about the proxying rules in a database.
Proxying rules are also replicated to a Redis instance, from where the actual
dynamic proxy will read them & route requests coming to it appropriately.

The db is the canonical information source, and hence we do not put anything in
Redis until the data has been commited to the database. Hence it is possible
for the db call to succeed and the redis call to fail, causing the db and
redis to be out of sync. Currently this is not really handled by the API."""
import flask
import json
import mwopenstackclients
import redis
import re

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
    cfg.StrOpt("sqlalchemy_uri", secret=True),
    cfg.StrOpt("redis_uri"),
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
        policy.RuleDefault("admin_or_member", "rule:admin or role:member"),
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

    Not represented at the Redis level at all
    """

    id = db.Column(db.Integer, primary_key=True)
    openstack_id = db.Column(db.String(256), unique=True)


class Route(db.Model):
    """Represents a route that has one matching rule & multiple backends

    Currently the only supported rule is to match entire domains"""

    id = db.Column(db.Integer, primary_key=True)
    domain = db.Column(db.String(256), unique=True)
    project_id = db.Column(db.Integer, db.ForeignKey("project.id"))
    project = db.relationship("Project", backref=db.backref("routes", lazy="dynamic"))


class Backend(db.Model):
    """Represents a backend that can have HTTP requests routed to it

    Usually has a URL that is of the form <protocol>://<hostname>:<port>"""

    id = db.Column(db.Integer, primary_key=True)
    url = db.Column(db.String(256))
    route_id = db.Column(db.Integer, db.ForeignKey("route.id"))
    route = db.relationship(
        "Route",
        backref=db.backref("backends", lazy="dynamic", cascade="all, delete-orphan"),
    )


class RedisStore:
    """Represents a redis instance that has routing info that the proxy reads"""

    def __init__(self, redis_conn):
        self.redis = redis_conn

    def delete_route(self, route: Route):
        self.redis.delete("frontend:" + route.domain)

    # Create this route if it does not already exist.
    def refresh_route(self, route: Route):
        key = "frontend:" + route.domain
        if not (self.redis.exists(key)):
            print("Adding new key: %s " % key)
            self.update_route(route)

    def update_route(self, route: Route, old_domain=None):
        key = "frontend:" + route.domain
        backends = [backend.url for backend in route.backends]

        pipeline = self.redis.pipeline()
        if old_domain:
            # When domains get renamed, kill old one too
            pipeline.delete("frontend:" + old_domain)
        pipeline.delete(key).sadd(key, *backends).execute()


class Dns:
    """Deals with any DNS writes."""

    def __init__(
        self, zones: dict, target_ipv4: str, clients: mwopenstackclients.Clients
    ):
        self.zones = zones
        self.target_ipv4 = target_ipv4
        self.clients = clients

    def designateclient(self, project) -> designateclient.Client:
        return designateclient.Client(session=self.clients.session(project))

    def get_zone(self, project: str, hostname: str):
        """Determines the Keystone project and DNS zone to use for a particular hostname."""
        if hostname[-1] != ".":
            hostname += "."

        hostname_parent = hostname[hostname.index(".") + 1:]

        # For now, regardless if the project owns that zone, ensure that
        # the used parent zone is explicitely allowed by the admins
        if hostname_parent in self.zones:
            if self.zones[hostname_parent].get("deprecated", False):
                enforce_policy("proxy:zones:use_deprecated", project)
            if self.zones[hostname_parent]["project"] != project and not self.zones[
                hostname_parent
            ].get("shared", False):
                log.logger.warning(
                    "Rejecting project %s from using non-shared zone %s in %s",
                    project,
                    hostname_parent,
                    self.zones[hostname_parent]["project"],
                )
                return None
            if hostname.startswith("*.") and self.zones[hostname_parent].get(
                "shared", False
            ):
                log.logger.warning(
                    "Rejecting project %s from using wildcard in shared zone %s",
                    project,
                    hostname_parent,
                )
                return None

            for zone in self.designateclient(project).zones.list():
                # we don't have multi-level wildcard certs
                if zone["name"] == hostname:
                    return (hostname, project, zone["id"])

            # TODO: check for conflicting other projects' zones?

            return (
                hostname,
                self.zones[hostname_parent]["project"],
                self.zones[hostname_parent]["id"],
            )

        log.logger.info(
            "Did not find zone for hostname %s (parent %s, supported zones %s)",
            hostname,
            hostname_parent,
            ", ".join(self.zones.keys()),
        )
        return None

    def can_use_hostname(self, project: str, hostname: str) -> bool:
        """Checks if the given project can use the given hostname."""
        zone = self.get_zone(project, hostname)
        if zone is None:
            return False

        hostname, project, zone_id = zone
        client = self.designateclient(project)

        existing_records = client.recordsets.list(
            zone_id, criterion={"name": hostname, "type": "A"}
        )
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
        client = self.designateclient(project)

        if not client.recordsets.list(
            zone_id, criterion={"name": hostname, "type": "A"}
        ):
            client.recordsets.create(zone_id, hostname, "A", [self.target_ipv4])

    def delete_records_for(self, project: str, hostname: str):
        hostname, project, zone_id = self.get_zone(project, hostname)
        client = self.designateclient(project)

        a_recordsets = client.recordsets.list(
            zone_id, criterion={"name": hostname, "type": "A"}
        )
        if a_recordsets:
            client.recordsets.delete(zone_id, a_recordsets[0]["id"])


with open(cfg.CONF.dynamicproxy.zones_json_file, "r") as f:
    zones = json.load(f)

redis_store = RedisStore(redis.Redis.from_url(cfg.CONF.dynamicproxy.redis_uri))
dns = Dns(
    zones,
    cfg.CONF.dynamicproxy.proxy_dns_ipv4,
    mwopenstackclients.Clients(
        username=cfg.CONF.dynamicproxy.dns_updater_username,
        password=cfg.CONF.dynamicproxy.dns_updater_password,
        project=cfg.CONF.dynamicproxy.dns_updater_project,
        url=cfg.CONF.dynamicproxy.dns_updater_keystone_api_url,
    ),
)


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
                    "backends": [backend.url for backend in route.backends],
                }
            )

    return flask.jsonify(**data)


@app.route("/v1/<project_id>/mapping", methods=["PUT"])
def create_mapping(project_id):
    data = flask.request.get_json(True)

    if (
        "domain" not in data
        or "backends" not in data
        or not isinstance(data["backends"], list)
    ):
        return "Valid JSON but invalid format. Needs domain string and backends array"
    domain = data["domain"]
    if not is_valid_domain(domain):
        return "Invalid domain", 400
    backend_urls = data["backends"]

    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        project = Project(openstack_id=project_id)
        db.session.add(project)

    route = Route.query.filter_by(domain=domain).first()
    if route is None:
        enforce_policy("proxy:create", project_id)
        if not dns.can_use_hostname(project_id, domain):
            return flask.jsonify({"error": f"Can't use domain {domain}"}), 403

        dns.add_records_for(project_id, domain)
        route = Route(domain=domain, project=project)
        db.session.add(route)
    elif route.project_id != project.id:
        return "Can't edit backend of another project", 403
    else:
        enforce_policy("proxy:update", project_id)

    for backend_url in backend_urls:
        # FIXME: Add validation for making sure these are valid
        backend = Backend(url=backend_url, route=route)
        db.session.add(backend)

    db.session.commit()

    redis_store.update_route(route)

    return "", 200


@app.route("/v1/<project_id>/mapping/<domain>", methods=["DELETE"])
def delete_mapping(project_id, domain):
    enforce_policy("proxy:delete", project_id)

    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        return "No such domain", 400

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 400

    db.session.delete(route)
    db.session.commit()

    redis_store.delete_route(route)

    dns.delete_records_for(project_id, domain)

    return "deleted", 200


@app.route("/v1/<project_id>/mapping/<domain>", methods=["GET"])
def get_mapping(project_id, domain):
    enforce_policy("proxy:view", project_id)

    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        return "No such domain", 400

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 400

    data = {
        "domain": route.domain,
        "backends": [backend.url for backend in route.backends],
    }

    return flask.jsonify(**data)


@app.route("/v1/<project_id>/mapping/<domain>", methods=["POST"])
def update_mapping(project_id, domain):
    project = Project.query.filter_by(openstack_id=project_id).first()
    if project is None:
        return "No such domain", 400

    enforce_policy("proxy:update", project_id)

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 400

    data = flask.request.get_json(True)

    if (
        "domain" not in data
        or "backends" not in data
        or not isinstance(data["backends"], list)
    ):
        return (
            "Valid JSON but invalid format. Needs domain string and backends array",
            400,
        )

    new_domain = data["domain"]
    if not is_valid_domain(new_domain):
        return "Invalid domain", 400
    backend_urls = data["backends"]

    if route.domain != new_domain:
        route.domain = new_domain
        db.session.add(route)

    # Not the most effecient, but I'm sitting in an airplane and this is the simplest from here
    route.backends.delete()
    for backend_url in backend_urls:
        route.backends.append(Backend(url=backend_url))
    db.session.add(route)
    db.session.commit()

    redis_store.update_route(route, old_domain=domain)

    return "OK", 200


def update_redis_from_db():
    projects = Project.query.all()

    for project in projects:
        for route in project.routes:
            print("Refreshing route:  %s " % route)
            redis_store.refresh_route(route)


update_redis_from_db()


if __name__ == "__main__":
    app.run(debug=True)
