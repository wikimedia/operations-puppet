#!/usr/bin/env python3
# ^ above line exists purely to make Jenkins test this using Python 3
import re
from typing import Optional

import pymysql
import yaml
from flask import Flask, Response, g, request
from flask_keystone import FlaskKeystone
from flask_oslolog import OsloLog
from oslo_config import cfg
from oslo_context import context
from oslo_policy import policy
from werkzeug.exceptions import HTTPException

cfgGroup = cfg.OptGroup("enc")
opts = [
    cfg.StrOpt("mysql_host"),
    cfg.StrOpt("mysql_db"),
    cfg.StrOpt("mysql_username", secret=True),
    cfg.StrOpt("mysql_password"),
    cfg.StrOpt("allowed_writers"),
]

key = FlaskKeystone()
log = OsloLog()

cfg.CONF.register_group(cfgGroup)
cfg.CONF.register_opts(opts, group=cfgGroup)

cfg.CONF(default_config_files=["/etc/puppet-enc-api/config.ini"])

enforcer = policy.Enforcer(cfg.CONF)
enforcer.register_defaults(
    [
        policy.RuleDefault("admin", "role:admin"),
        policy.RuleDefault(
            "admin_or_projectadmin", "rule:admin or role:projectadmin"
        ),
        policy.RuleDefault("prefix:index", ""),
        policy.RuleDefault("prefix:view", ""),
        policy.RuleDefault("prefix:create", "rule:admin_or_projectadmin"),
        policy.RuleDefault("prefix:update", "rule:admin_or_projectadmin"),
        policy.RuleDefault("prefix:delete", "rule:admin_or_projectadmin"),
        policy.RuleDefault("project:index", ""),
        policy.RuleDefault("puppetrole:index", ""),
        policy.RuleDefault("puppetrole:view", ""),
    ]
)

app = Flask(__name__)


key.init_app(app)
log.init_app(app)


def _preprocess_prefix(prefix):
    """
    Preprocess prefixes to provide some convenience features

    - Take a single _ to mean empty. The empty prefix applies to all
      instances in a project, and this makes it easier than trying
      to have an empty url segment
    """
    if prefix == "_":
        return ""

    # If the VM thinks it's under .eqiad.wmflabs, give it
    #  a .eqiad1.wikimedia.cloud config anyway.
    prefix = re.sub(r"\.eqiad\.wmflabs$", ".eqiad1.wikimedia.cloud", prefix)

    return prefix


class Forbidden(HTTPException):
    code = 403
    description = "Forbidden."


def enforce_policy(rule: str, project_id: Optional[str]):
    # headers in a specific format that oslo.context wants
    headers = {
        "HTTP_{}".format(name.upper().replace("-", "_")): value
        for name, value in request.headers.items()
    }

    ctx = context.RequestContext.from_environ(headers)

    if project_id:
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
        project_id,
    )

    scope = {"project_id": project_id} if project_id else {}

    enforcer.authorize(
        rule,
        scope,
        ctx,
        do_raise=True,
        exc=Forbidden,
    )


@app.before_request
def before_request():
    g.db = pymysql.connect(
        host=cfg.CONF.enc.mysql_host,
        db=cfg.CONF.enc.mysql_db,
        user=cfg.CONF.enc.mysql_username,
        passwd=cfg.CONF.enc.mysql_password,
        charset="utf8",
    )

    g.allowed_writers = [
        writer.strip() for writer in cfg.CONF.enc.allowed_writers.split(",")
    ]


@app.teardown_request
def teardown_request(exception):
    db = getattr(g, "db", None)
    if db is not None:
        db.close()


@app.route("/v1/<string:project>/prefix/<string:prefix>/roles", methods=["GET"])
@key.login_required
def get_roles(project, prefix):
    enforce_policy("prefix:view", project)
    prefix = _preprocess_prefix(prefix)
    cur = g.db.cursor()
    try:
        cur.execute(
            """
                SELECT roleassignment.role FROM prefix, roleassignment
                WHERE prefix.project = %s AND prefix.prefix = %s AND
                    prefix.id = roleassignment.prefix_id
            """,
            (project, prefix),
        )
        roles = [r[0] for r in cur.fetchall()]
        if len(roles) == 0:
            return Response(
                yaml.dump({"status": "notfound"}),
                status=404,
                mimetype="application/x-yaml",
            )
        return Response(
            yaml.dump({"roles": roles}),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route("/v1/roles", methods=["GET"])
@key.login_required
def get_all_roles():
    enforce_policy("puppetrole:index", None)
    cur = g.db.cursor()
    try:
        cur.execute("SELECT distinct roleassignment.role FROM roleassignment")
        roles = [r[0] for r in cur.fetchall()]
        if len(roles) == 0:
            return Response(
                yaml.dump({"status": "notfound"}),
                status=404,
                mimetype="application/x-yaml",
            )
        return Response(
            yaml.dump({"roles": roles}),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route("/v1/projects", methods=["GET"])
@key.login_required
def get_all_projects():
    enforce_policy("project:index", None)
    cur = g.db.cursor()
    try:
        cur.execute("SELECT distinct prefix.project FROM prefix")
        projects = [r[0] for r in cur.fetchall()]
        if len(projects) == 0:
            return Response(
                yaml.dump({"status": "notfound"}),
                status=404,
                mimetype="application/x-yaml",
            )
        return Response(
            yaml.dump({"projects": projects}),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route(
    "/v1/<string:project>/prefix/<string:prefix>/roles", methods=["POST"]
)
@key.login_required
def set_roles(project, prefix):
    enforce_policy("prefix:update", project)
    if request.remote_addr not in g.allowed_writers:
        return Response(
            yaml.dump({"status": "forbidden"}),
            status=403,
            mimetype="application/x-yaml",
        )

    prefix = _preprocess_prefix(prefix)
    try:
        roles = yaml.safe_load(request.data)
    except yaml.YAMLError:
        return Response(
            yaml.dump(
                {
                    "status": "fail",
                    "message": "Unable to parse input provided as YAML",
                }
            ),
            status=400,
            mimetype="application/x-yaml",
        )
    if type(roles) is not list:
        return Response(
            yaml.dump(
                {"status": "fail", "message": "Provided YAML should be a list"}
            ),
            status=400,
            mimetype="application/x-yaml",
        )
    # TODO: Add more validation for roles?
    cur = g.db.cursor()
    try:
        g.db.begin()
        # Create this prefix if it does not exist yet!
        # This monstrosity because http://stackoverflow.com/a/779252
        cur.execute(
            """
                INSERT INTO prefix (project, prefix) VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)
            """,
            (project, prefix),
        )
        prefix_id = cur.lastrowid
        # We delete all the role associations for this prefix and then
        # re-insert the ones we have. This causes churn in the roleassignment
        # tables, but seems cleaner than the alternatives.
        cur.execute(
            "DELETE FROM roleassignment WHERE prefix_id = %s",
            (prefix_id,),
        )
        # Add the new ones!
        cur.executemany(
            "INSERT INTO roleassignment (prefix_id, role) VALUES (%s, %s)",
            [(prefix_id, role) for role in roles],
        )
        g.db.commit()
    finally:
        cur.close()
    return Response(
        yaml.dump({"status": "ok"}), status=200, mimetype="application/x-yaml"
    )


@app.route("/v1/<string:project>/prefix/<string:prefix>/hiera", methods=["GET"])
@key.login_required
def get_hiera(project, prefix):
    enforce_policy("prefix:view", project)
    prefix = _preprocess_prefix(prefix)
    cur = g.db.cursor()
    try:
        cur.execute(
            """
            SELECT hieraassignment.hiera_data FROM prefix, hieraassignment
            WHERE prefix.project = %s AND prefix.prefix = %s AND
                  prefix.id = hieraassignment.prefix_id
        """,
            (project, prefix),
        )
        row = cur.fetchone()
        if row is None:
            return Response(
                yaml.dump({"status": "notfound"}),
                status=404,
                mimetype="application/x-yaml",
            )
        return Response(
            yaml.dump({"hiera": row[0]}),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route(
    "/v1/<string:project>/prefix/<string:prefix>/hiera", methods=["POST"]
)
@key.login_required
def set_hiera(project, prefix):
    enforce_policy("prefix:update", project)
    if request.remote_addr not in g.allowed_writers:
        return Response(
            yaml.dump({"status": "forbidden"}),
            status=403,
            mimetype="application/x-yaml",
        )

    prefix = _preprocess_prefix(prefix)
    try:
        hiera = yaml.safe_load(request.data)
    except yaml.YAMLError:
        return Response(
            yaml.dump(
                {
                    "status": "fail",
                    "message": "Unable to parse input provided as YAML",
                }
            ),
            status=400,
            mimetype="application/x-yaml",
        )
    if type(hiera) is not dict:
        return Response(
            yaml.dump(
                {
                    "status": "fail",
                    "message": "Provided YAML should be a dictionary",
                }
            ),
            status=400,
            mimetype="application/x-yaml",
        )
    # TODO: Add more validation for hiera?
    cur = g.db.cursor()
    try:
        g.db.begin()
        # Create this prefix if it does not exist yet!
        # This monstrosity because http://stackoverflow.com/a/779252
        cur.execute(
            """
                INSERT INTO prefix (project, prefix) VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)
            """,
            (project, prefix),
        )
        prefix_id = cur.lastrowid
        # Add the new ones!
        cur.execute(
            """
                INSERT INTO hieraassignment (prefix_id, hiera_data) VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE hiera_data=%s
            """,
            (prefix_id, request.data, request.data),
        )
        g.db.commit()
    finally:
        cur.close()
    return Response(
        yaml.safe_dump({"status": "ok"}),
        status=200,
        mimetype="application/x-yaml",
    )


# No @key.login_required, since this one is queried by Puppetmasters
@app.route("/v1/<string:project>/node/<string:fqdn>", methods=["GET"])
def get_node_config(project, fqdn):

    # If the VM thinks it's under .eqiad.wmflabs, give it
    #  a .eqiad1.wikimedia.cloud config anyway.
    fqdn = re.sub(r"\.eqiad\.wmflabs$", ".eqiad1.wikimedia.cloud", fqdn)

    cur = g.db.cursor()
    roles = []
    try:
        cur.execute(
            """
                SELECT role
                FROM roleassignment
                WHERE prefix_id in (
                    SELECT id
                    FROM prefix
                    WHERE project = %s
                    AND %s LIKE CONCAT(prefix, '%%')
                )
            """,
            (project, fqdn),
        )
        for row in cur.fetchall():
            roles.append(row[0])

        cur.execute(
            """
                SELECT prefix, hiera_data
                FROM prefix, hieraassignment
                WHERE prefix_id in (
                    SELECT id
                    FROM prefix
                    WHERE project = %s
                    AND %s LIKE CONCAT(prefix, '%%')
                ) AND prefix.id = prefix_id
                ORDER BY CHAR_LENGTH(prefix)
            """,
            (project, fqdn),
        )
        hiera = {}
        for row in cur.fetchall():
            hiera.update(yaml.safe_load(row[1]))
    finally:
        cur.close()
    return Response(
        yaml.safe_dump({"roles": roles, "hiera": hiera}),
        status=200,
        mimetype="application/x-yaml",
    )


@app.route("/v1/<string:project>/prefix", methods=["GET"])
@key.login_required
def get_prefixes(project):
    enforce_policy("prefix:index", project)
    cur = g.db.cursor()
    try:
        cur.execute(
            "SELECT prefix FROM prefix WHERE project = %s",
            (project,),
        )
        # Do the inverse of _preprocess_prefix, so callers get a consistent view
        return Response(
            yaml.safe_dump(
                {
                    "prefixes": [
                        "_" if r[0] == b"" or r[0] == "" else r[0]
                        for r in cur.fetchall()
                    ]
                }
            ),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route("/v1/<string:project>/prefix/<string:role>", methods=["GET"])
@key.login_required
def get_prefixes_for_project_and_role(project, role):
    enforce_policy("prefix:index", project)
    cur = g.db.cursor()
    try:
        cur.execute(
            """
                SELECT prefix.prefix FROM prefix, roleassignment
                WHERE prefix.project = %s AND
                    roleassignment.role = %s AND
                    prefix.id = roleassignment.prefix_id
            """,
            (project, role),
        )
        # Do the inverse of _preprocess_prefix, so callers get a consistent view
        return Response(
            yaml.safe_dump(
                {
                    "prefixes": [
                        "_" if r[0] == b"" or r[0] == "" else r[0]
                        for r in cur.fetchall()
                    ]
                }
            ),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route("/v1/prefix/<string:role>", methods=["GET"])
@key.login_required
def get_prefixes_for_role(role):
    enforce_policy("puppetrole:view", None)
    cur = g.db.cursor()
    try:
        cur.execute(
            """
                SELECT prefix.project, prefix.prefix FROM prefix, roleassignment
                WHERE roleassignment.role = %s AND
                      prefix.id = roleassignment.prefix_id
            """,
            (role),
        )
        # Return a list of project dicts with '_' meaning 'everything':
        rdict = {}
        for r in cur.fetchall():
            project = r[0]
            prefix = r[1]
            if project not in rdict:
                rdict[project] = {"prefixes": []}
            rdict[project]["prefixes"].append(
                "_" if prefix == b"" or prefix == "" else r[1]
            )
        return Response(
            yaml.safe_dump(rdict), status=200, mimetype="application/x-yaml"
        )
    finally:
        cur.close()


@app.route("/v1/<string:project>/prefix/<string:prefix>", methods=["DELETE"])
@key.login_required
def delete_prefix(project, prefix):
    enforce_policy("prefix:delete", project)
    if request.remote_addr not in g.allowed_writers:
        return Response(
            yaml.dump({"status": "forbidden"}),
            status=403,
            mimetype="application/x-yaml",
        )

    prefix = _preprocess_prefix(prefix)
    cur = g.db.cursor()
    try:
        cur.execute(
            "SELECT id  FROM prefix WHERE project = %s and prefix = %s",
            (project, prefix),
        )
        row = cur.fetchone()

        if not row:
            return Response(
                yaml.dump({"status": "notfound"}),
                status=404,
                mimetype="application/x-yaml",
            )

        prefix_id = row[0]

        g.db.begin()
        cur.execute(
            "DELETE FROM roleassignment WHERE prefix_id = %s",
            (prefix_id,),
        )

        cur.execute(
            "DELETE FROM hieraassignment WHERE prefix_id = %s",
            (prefix_id,),
        )

        cur.execute(
            "DELETE FROM prefix WHERE id = %s",
            (prefix_id,),
        )
        g.db.commit()

        return Response(
            yaml.safe_dump({"status": "ok"}),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


@app.route("/v1/healthz")
def healthz():
    """
    Where we do a token db operation to check the health of the whole application.
    """
    cur = g.db.cursor()
    try:
        cur.execute("SHOW TABLES")
        cur.fetchall()

        return Response(
            yaml.safe_dump({"status": "ok"}),
            status=200,
            mimetype="application/x-yaml",
        )
    finally:
        cur.close()


if __name__ == "__main__":
    app.run(debug=True)
