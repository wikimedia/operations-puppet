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
import redis
import re

from flask_keystone import FlaskKeystone
from flask_oslolog import OsloLog
from flask_sqlalchemy import SQLAlchemy
from oslo_config import cfg
from oslo_context import context
from oslo_policy import policy
from werkzeug.exceptions import HTTPException

cfgGroup = cfg.OptGroup('dynamicproxy')
opts = [
    cfg.StrOpt('sqlalchemy_uri'),
]

key = FlaskKeystone()
log = OsloLog()

cfg.CONF.register_group(cfgGroup)
cfg.CONF.register_opts(opts, group=cfgGroup)

cfg.CONF(default_config_files=['/etc/dynamicproxy-api/config.ini'])

enforcer = policy.Enforcer(cfg.CONF)
enforcer.register_defaults([
    policy.RuleDefault('admin', 'role:admin'),
    policy.RuleDefault('admin_or_projectadmin', 'rule:admin or role:projectadmin'),
    policy.RuleDefault('proxy:index', ''),
    policy.RuleDefault('proxy:view', ''),
    policy.RuleDefault('proxy:create', 'rule:admin_or_projectadmin'),
    policy.RuleDefault('proxy:update', 'rule:admin_or_projectadmin'),
    policy.RuleDefault('proxy:delete', 'rule:admin_or_projectadmin'),
])

app = flask.Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = cfg.CONF.dynamicproxy.sqlalchemy_uri

db = SQLAlchemy(app)

key.init_app(app)
log.init_app(app)


class Project(db.Model):
    """Represents a Wikitech Project.
    Primary unit of access control.
    Note: No access control implemented yet :P

    Not represented at the Redis level at all"""
    id = db.Column(db.Integer, primary_key=True)
    # this is actually what openstack calls "project id"
    name = db.Column(db.String(256), unique=True)

    def __init__(self, name):
        self.name = name


class Route(db.Model):
    """Represents a route that has one matching rule & multiple backends

    Currently the only supported rule is to match entire domains"""
    id = db.Column(db.Integer, primary_key=True)
    domain = db.Column(db.String(256), unique=True)
    project_id = db.Column(db.Integer, db.ForeignKey('project.id'))
    project = db.relationship('Project',
                              backref=db.backref('routes', lazy='dynamic'))

    def __init__(self, domain):
        self.domain = domain


class Backend(db.Model):
    """Represents a backend that can have HTTP requests routed to it

    Usually has a URL that is of the form <protocol>://<hostname>:<port>"""
    id = db.Column(db.Integer, primary_key=True)
    url = db.Column(db.String(256))
    route_id = db.Column(db.Integer, db.ForeignKey('route.id'))
    route = db.relationship('Route',
                            backref=db.backref('backends', lazy='dynamic'))

    def __init__(self, url):
        self.url = url


class RedisStore(object):
    """Represents a redis instance that has routing info that the proxy reads"""
    def __init__(self, redis_conn):
        self.redis = redis_conn

    def delete_route(self, route):
        self.redis.delete('frontend:' + route.domain)

    # Create this route if it does not already exist.
    def refresh_route(self, route):
        key = 'frontend:' + route.domain
        if not (self.redis.exists(key)):
            print("Adding new key: %s " % key)
            self.update_route(route)

    def update_route(self, route, old_domain=None):
        key = 'frontend:' + route.domain
        backends = [backend.url for backend in route.backends]

        pipeline = self.redis.pipeline()
        if old_domain:
            # When domains get renamed, kill old one too
            pipeline.delete('frontend:' + old_domain)
        pipeline.delete(key).sadd(key, *backends).execute()


redis_store = RedisStore(redis.Redis())


class Forbidden(HTTPException):
    code = 403
    description = 'Forbidden.'


def is_valid_domain(hostname):
    """
    Credit for this function goes to Tim Pietzcker and other StackOverflow contributors
    See https://stackoverflow.com/a/2532344
    """
    if len(hostname) > 255:
        return False
    if hostname[-1] == ".":
        # strip exactly one dot from the right, if present
        hostname = hostname[:-1]
    allowed = re.compile("(?!-)[A-Z\d-]{1,63}(?<!-)$", re.IGNORECASE)
    return all(allowed.match(x) for x in hostname.split("."))


def environify_header_name(name):
    return "HTTP_{}".format(name.upper().replace('-', '_'))


def enforce_policy(rule, project_id):
    # headers in a specific format that oslo.context wants
    headers = {environify_header_name(name): value for name, value in flask.request.headers.items()}
    ctx = context.RequestContext.from_environ(headers)

    # if the project in the url is for a different project than what
    # the keystone token is, error out early.
    if ctx.project_id != project_id:
        raise Forbidden("Invalid project id.")

    enforcer.authorize(
        rule,
        {'project_id': project_id},
        ctx,
        do_raise=True,
        exc=Forbidden,
    )


@app.route('/v1/<project_name>/mapping', methods=['GET'])
def all_mappings(project_name):
    enforce_policy('proxy:index', project_name)

    project = Project.query.filter_by(name=project_name).first()
    if project is None:
        return "No such project", 400

    data = {'project': project.name, 'routes': []}
    for route in project.routes:
        data['routes'].append({
            'domain': route.domain,
            'backends': [backend.url for backend in route.backends]
        })

    return flask.jsonify(**data)


@app.route('/v1/<project_name>/mapping', methods=['PUT'])
def create_mapping(project_name):
    data = flask.request.get_json(True)

    if 'domain' not in data or 'backends' not in data or not isinstance(data['backends'], list):
        return "Valid JSON but invalid format. Needs domain string and backends array"
    domain = data['domain']
    if not is_valid_domain(domain):
        return "Invalid domain", 400
    backend_urls = data['backends']

    project = Project.query.filter_by(name=project_name).first()
    if project is None:
        project = Project(project_name)
        db.session.add(project)

    route = Route.query.filter_by(domain=domain).first()
    if route is None:
        enforce_policy('proxy:create', project_name)
        route = Route(domain)
        route.project = project
        db.session.add(route)
    elif route.project_id != project.id:
        return "Can't edit backend of another project", 403
    else:
        enforce_policy('proxy:update', project_name)

    for backend_url in backend_urls:
        # FIXME: Add validation for making sure these are valid
        backend = Backend(backend_url)
        backend.route = route
        db.session.add(backend)

    db.session.commit()

    redis_store.update_route(route)

    return "", 200


@app.route('/v1/<project_name>/mapping/<domain>', methods=['DELETE'])
def delete_mapping(project_name, domain):
    enforce_policy('proxy:delete', project_name)

    project = Project.query.filter_by(name=project_name).first()
    if project is None:
        return "No such project", 400

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 400

    db.session.delete(route)
    db.session.commit()

    redis_store.delete_route(route)

    return "deleted", 200


@app.route('/v1/<project_name>/mapping/<domain>', methods=['GET'])
def get_mapping(project_name, domain):
    enforce_policy('proxy:view', project_name)

    project = Project.query.filter_by(name=project_name).first()
    if project is None:
        return "No such project", 400

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 400

    data = {'domain': route.domain, 'backends': [backend.url for backend in route.backends]}

    return flask.jsonify(**data)


@app.route('/v1/<project_name>/mapping/<domain>', methods=['POST'])
def update_mapping(project_name, domain):
    project = Project.query.filter_by(name=project_name).first()
    if project is None:
        return "No such project", 400

    enforce_policy('proxy:update', project_name)

    route = Route.query.filter_by(project=project, domain=domain).first()
    if route is None:
        return "No such domain", 400

    data = flask.request.get_json(True)

    if 'domain' not in data or 'backends' not in data or not isinstance(data['backends'], list):
        return "Valid JSON but invalid format. Needs domain string and backends array", 400

    new_domain = data['domain']
    if not is_valid_domain(new_domain):
        return "Invalid domain", 400
    backend_urls = data['backends']

    if route.domain != new_domain:
        route.domain = new_domain
        db.session.add(route)

    # Not the most effecient, but I'm sitting in an airplane and this is the simplest from here
    route.backends.delete()
    for backend_url in backend_urls:
        route.backends.append(Backend(backend_url))
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


if __name__ == '__main__':
    app.run(debug=True)
