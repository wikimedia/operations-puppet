from flask import Flask, request, g, Response
from statsd.defaults.env import statsd
import pymysql
import os
import yaml

app = Flask(__name__)
# Propogate exceptions to the uwsgi log
app.config['PROPAGATE_EXCEPTIONS'] = True


def _preprocess_prefix(prefix):
    """
    Preprocess prefixes to provide some convenience features

    - Take a single _ to mean empty. The empty prefix applies to all
      instances in a project, and this makes it easier than trying
      to have an empty url segment
    """
    if prefix == '_':
        return ''
    return prefix


@app.before_request
def before_request():
    g.db = pymysql.connect(
        host=os.environ['MYSQL_HOST'],
        db=os.environ['MYSQL_DB'],
        user=os.environ['MYSQL_USERNAME'],
        passwd=os.environ['MYSQL_PASSWORD'],
        charset='utf8'
    )


@app.teardown_request
def teardown_request(exception):
    db = getattr(g, 'db', None)
    if db is not None:
        db.close()


@statsd.timer('get_roles')
@app.route('/v1/<string:project>/prefix/<string:prefix>/roles', methods=['GET'])
def get_roles(project, prefix):
    prefix = _preprocess_prefix(prefix)
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT roleassignment.role FROM prefix, roleassignment
            WHERE prefix.project = %s AND prefix.prefix = %s AND
                  prefix.id = roleassignment.prefix_id
        """, (project, prefix))
        roles = [r[0] for r in cur.fetchall()]
        if len(roles) == 0:
            return Response(
                yaml.dump({'status': 'notfound'}),
                status=404,
                mimetype='application/x-yaml'
            )
        return Response(
            yaml.dump({'roles': roles}),
            status=200,
            mimetype='application/x-yaml'
        )
    finally:
        cur.close()


@statsd.timer('set_roles')
@app.route('/v1/<string:project>/prefix/<string:prefix>/roles', methods=['POST'])
def set_roles(project, prefix):
    prefix = _preprocess_prefix(prefix)
    try:
        roles = yaml.safe_load(request.data)
    except yaml.YAMLError:
        return Response(
            yaml.dump({
                'status': 'fail',
                'message': 'Unable to parse input provided as YAML'
            }),
            status=400,
            mimetype='application/x-yaml'
        )
    if type(roles) is not list:
        return Response(
            yaml.dump({
                'status': 'fail',
                'message': 'Provided YAML should be a list'
            }),
            status=400,
            mimetype='application/x-yaml'
        )
    # TODO: Add more validation for roles?
    cur = g.db.cursor()
    try:
        g.db.begin()
        # Create this prefix if it does not exist yet!
        # This monstrosity because http://stackoverflow.com/a/779252
        cur.execute("""
            INSERT INTO prefix (project, prefix) VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)
        """, (project, prefix))
        prefix_id = cur.lastrowid
        # We delete all the role associations for this prefix and then
        # re-insert the ones we have. This causes churn in the roleassignment
        # tables, but seems cleaner than the alternatives.
        cur.execute("""
            DELETE FROM roleassignment WHERE prefix_id = %s
        """, (prefix_id, ))
        # Add the new ones!
        cur.executemany("""
            INSERT INTO roleassignment (prefix_id, role) VALUES (%s, %s)
        """, [(prefix_id, role) for role in roles])
        g.db.commit()
    finally:
        cur.close()
    return Response(
        yaml.dump({'status': 'ok'}),
        status=200,
        mimetype='application/x-yaml'
    )


@statsd.timer('get_hiera')
@app.route('/v1/<string:project>/prefix/<string:prefix>/hiera', methods=['GET'])
def get_hiera(project, prefix):
    prefix = _preprocess_prefix(prefix)
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT hieraassignment.hiera_data FROM prefix, hieraassignment
            WHERE prefix.project = %s AND prefix.prefix = %s AND
                  prefix.id = hieraassignment.prefix_id
        """, (project, prefix))
        row = cur.fetchone()
        if row is None:
            return Response(
                yaml.dump({'status': 'notfound'}),
                status=404,
                mimetype='application/x-yaml'
            )
        return Response(
            yaml.dump({'hiera': row[0]}),
            status=200,
            mimetype='application/x-yaml'
        )
    finally:
        cur.close()


@statsd.timer('set_hiera')
@app.route('/v1/<string:project>/prefix/<string:prefix>/hiera', methods=['POST'])
def set_hiera(project, prefix):
    prefix = _preprocess_prefix(prefix)
    try:
        hiera = yaml.safe_load(request.data)
    except yaml.YAMLError:
        return Response(
            yaml.dump({
                'status': 'fail',
                'message': 'Unable to parse input provided as YAML'
            }),
            status=400,
            mimetype='application/x-yaml'
        )
    if type(hiera) is not dict:
        return Response(
            yaml.dump({
                'status': 'fail',
                'message': 'Provided YAML should be a dictionary'
            }),
            status=400,
            mimetype='application/x-yaml'
        )
    # TODO: Add more validation for hiera?
    cur = g.db.cursor()
    try:
        g.db.begin()
        # Create this prefix if it does not exist yet!
        # This monstrosity because http://stackoverflow.com/a/779252
        cur.execute("""
            INSERT INTO prefix (project, prefix) VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)
        """, (project, prefix))
        prefix_id = cur.lastrowid
        # Add the new ones!
        cur.execute("""
            INSERT INTO hieraassignment (prefix_id, hiera_data) VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE hiera_data=%s
        """, (prefix_id, request.data, request.data))
        g.db.commit()
    finally:
        cur.close()
    return Response(
        yaml.safe_dump({'status': 'ok'}),
        status=200,
        mimetype='application/x-yaml'
    )


@statsd.timer('get_node_config')
@app.route('/v1/<string:project>/node/<string:fqdn>', methods=['GET'])
def get_node_config(project, fqdn):
    cur = g.db.cursor()
    roles = []
    try:
        cur.execute("""
            SELECT role
            FROM roleassignment
            WHERE prefix_id in (
                SELECT id
                FROM prefix
                WHERE project = %s
                AND %s LIKE CONCAT(prefix, '%%')
            )
        """, (project, fqdn))
        for row in cur.fetchall():
            roles.append(row[0])

        cur.execute("""
            SELECT prefix, hiera_data
            FROM prefix, hieraassignment
            WHERE prefix_id in (
                SELECT id
                FROM prefix
                WHERE project = %s
                AND %s LIKE CONCAT(prefix, '%%')
            ) AND prefix.id = prefix_id
            ORDER BY CHAR_LENGTH(prefix)
        """, (project, fqdn))
        hiera = {}
        for row in cur.fetchall():
            hiera.update(yaml.safe_load(row[1]))
    finally:
        cur.close()
    return Response(
        yaml.safe_dump({'roles': roles, 'hiera': hiera}),
        status=200,
        mimetype='application/x-yaml'
    )


@statsd.timer('get_prefixes')
@app.route('/v1/<string:project>/prefix', methods=['GET'])
def get_prefixes(project):
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT prefix FROM prefix WHERE project = %s
        """, (project, ))
        # Do the inverse of _preprocess_prefix, so callers get a consistent view
        return Response(
            yaml.safe_dump({
                'prefixes':
                ['_' if r[0] == b'' or r[0] == ''
                 else r[0] for r in cur.fetchall()]}),
            status=200,
            mimetype='application/x-yaml'
        )
    finally:
        cur.close()


@statsd.timer('get_prefixes_for_project_and_role')
@app.route('/v1/<string:project>/prefix/<string:role>', methods=['GET'])
def get_prefixes_for_project_and_role(project, role):
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT prefix.prefix FROM prefix, roleassignment
                WHERE prefix.project = %s AND
                      roleassignment.role = %s AND
                      prefix.id = roleassignemnt.prefix_id
        """, (project, role))
        # Do the inverse of _preprocess_prefix, so callers get a consistent view
        return Response(
            yaml.safe_dump({
                'prefixes':
                ['_' if r[0] == b'' or r[0] == ''
                 else r[0] for r in cur.fetchall()]}),
            status=200,
            mimetype='application/x-yaml'
        )
    finally:
        cur.close()


@statsd.timer('get_prefixes_for_role')
@app.route('/v1/prefix/<string:role>', methods=['GET'])
def get_prefixes_for_role(role):
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT prefix.project, prefix.prefix FROM prefix, roleassignment
                WHERE roleassignment.role = %s AND
                      prefix.id = roleassignemnt.prefix_id
        """, (role))
        # Return a list of project dicts with '_' meaning 'everything':
        rdict = {}
        for r in cur.fetchall():
            project = r[0]
            prefix = r[1]
            if project not in rdict:
                rdict[project] = {'prefixes': []}
            rdict[project]['prefixes'].append('_' if prefix == b''
                                              or prefix == '' else r[0])
        return Response(yaml.safe_dump(rdict),
                        status=200,
                        mimetype='application/x-yaml')
    finally:
        cur.close()


@statsd.timer('delete_prefix')
@app.route('/v1/<string:project>/prefix/<string:prefix>', methods=['DELETE'])
def delete_prefix(project, prefix):
    prefix = _preprocess_prefix(prefix)
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT id  FROM prefix WHERE project = %s and prefix = %s
        """, (project, prefix))
        prefix_id = cur.fetchone()[0]

        if not prefix_id:
            return Response(
                yaml.dump({'status': 'notfound'}),
                status=404,
                mimetype='application/x-yaml'
            )

        g.db.begin()
        cur.execute("""
            DELETE FROM roleassignment WHERE prefix_id = %s
        """, (prefix_id, ))

        cur.execute("""
            DELETE FROM hieraassignment WHERE prefix_id = %s
        """, (prefix_id, ))

        cur.execute("""
            DELETE FROM prefix WHERE id = %s
        """, (prefix_id, ))
        g.db.commit()

        return Response(
            yaml.safe_dump({'status': 'ok'}),
            status=200,
            mimetype='application/x-yaml'
        )
    finally:
        cur.close()


@statsd.timer('healthz')
@app.route('/v1/healthz')
def healthz():
    """
    Where we do a token db operation to check the health of the whole application.
    """
    cur = g.db.cursor()
    try:
        cur.execute("""
            SHOW TABLES
        """)
        cur.fetchall()
        return Response(
            yaml.safe_dump({'status': 'ok'}),
            status=200,
            mimetype='application/x-yaml'
        )
    finally:
        cur.close()


if __name__ == '__main__':
    app.run(debug=True)
