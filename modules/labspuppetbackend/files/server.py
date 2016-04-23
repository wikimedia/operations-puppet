from flask import Flask, request, g
import pymysql
import os
import json

app = Flask(__name__)


@app.before_request
def before_request():
    g.db = pymysql.connect(
        host=os.environ['MYSQL_HOST'],
        db=os.environ['MYSQL_DB'],
        user=os.environ['MYSQL_USERNAME'],
        passwd=os.environ['MYSQL_PASSWORD']
    )


@app.teardown_request
def teardown_request(exception):
    db = getattr(g, 'db', None)
    if db is not None:
        db.close()


@app.route('/v1/<string:project>/prefix/<string:prefix>/roles', methods=['GET'])
def get_roles(project, prefix):
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT roleassignment.role FROM prefix, roleassignment
            WHERE prefix.project = %s AND prefix.prefix = %s AND
                  prefix.id = roleassignment.prefix_id
        """, (project, prefix))
        roles = [r[0] for r in cur.fetchall()]
        return json.dumps(roles)
    finally:
        cur.close()


@app.route('/v1/<string:project>/prefix/<string:prefix>/roles', methods=['POST'])
def set_roles(project, prefix):
    roles = request.get_json()
    if type(roles) is not list:
        return "Body should be a JSON array of roles to set", 400
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
    return 'OK'


@app.route('/v1/<string:project>/prefix/<string:prefix>/hiera', methods=['GET'])
def get_hiera(project, prefix):
    cur = g.db.cursor()
    try:
        cur.execute("""
            SELECT hieraassignment.hiera_data FROM prefix, hieraassignment
            WHERE prefix.project = %s AND prefix.prefix = %s AND
                  prefix.id = hieraassignment.prefix_id
        """, (project, prefix))
        return json.dumps(cur.fetchone()[0])
    finally:
        cur.close()


@app.route('/v1/<string:project>/prefix/<string:prefix>/hiera', methods=['POST'])
def set_hiera(project, prefix):
    hiera = request.get_json()
    if type(hiera) is not dict:
        return "Body should be a JSON dict of hiera to set", 400
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
    return 'OK'


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
            hiera.update(json.loads(row[1]))
    finally:
        cur.close()
    return json.dumps({
        'roles': roles,
        'hiera': hiera
    })


@app.route('/v1/<string:project>/prefix', methods=['GET'])
def get_prefixes(project):
    return project

if __name__ == '__main__':
    app.run(debug=True)
