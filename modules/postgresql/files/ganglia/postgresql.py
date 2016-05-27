#!/bin/env python

import os
import threading
import time
import psycopg2

descriptors = list()
_Worker_Thread = None
_Lock = threading.Lock()  # synchronization lock
metric_results = {}


def metric_of(name):
    global metric_results
    return metric_results.get(name, 0)

# These are the defaults set for the metric attributes
Desc_Skel = {
    "name": "N/A",
    "call_back": metric_of,
    "time_max": 60,
    "value_type": "uint",
    "units": "N/A",
    "slope": "both",  # zero|positive|negative|both
    "format": "%d",
    "description": "N/A",
    "groups": "PostgreSQL",
    }

# Create your queries here. Keys whose names match those defined in the default
# set are overridden. Any additional key-value pairs (i.e. query) will not be
# added to the Ganglia metric definition but can be useful for data purposes.
metric_defs = {
    "pg_backends_waiting": {
        "description": "Number of postgres backends that are waiting",
        "units": "backends",
        "query": "SELECT count(*) AS backends_waiting FROM " +
                 "pg_stat_activity WHERE waiting = 't';"
    },
    "pg_database_size": {
        "description": "Total size of all databases in bytes",
        "value_type": "double",
        "format": "%.0f",
        "units": "bytes",
        "query": "SELECT sum(pg_database_size(d.oid)) AS " +
                 "size_database FROM pg_database d ORDER BY 1 DESC;"
    },
    "pg_idx_blks_read": {
        "description": "Total index blocks read",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(idx_blks_read) AS idx_blks_read " +
                 "FROM pg_statio_all_indexes;"
    },
    "pg_idx_blks_hit": {
        "description": "Total index blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(idx_blks_hit) AS idx_blks_hit " +
                 "FROM pg_statio_all_indexes;"
    },
    "pg_locks": {
        "description": "Number of locks held",
        "units": "locks",
        "query": "SELECT count(*) FROM pg_locks;"
    },
    "pg_query_time_idle_in_txn": {
        "description": 'Age of longest _idle in transaction_ transaction',
        "units": "seconds",
        "query": "SELECT COALESCE(max(COALESCE(ROUND(EXTRACT(epoch " +
                 "FROM now()-query_start)),0)),0) AS " +
                 "query_time_idle_in_txn FROM pg_stat_activity " +
                 "WHERE current_query = '% in transaction';"
    },
    "pg_max_idle_txn_time": {
        "description": "Age of longest idle transaction",
        "units": "seconds",
        "query": "SELECT COALESCE(max(COALESCE(ROUND(EXTRACT(epoch " +
                 "FROM now()-query_start)),0)),0) as query_time_max FROM " +
                 "pg_stat_activity WHERE current_query <> '<IDLE>';"
    },
    "pg_txn_time_max": {
        "description": "Age of longest transaction",
        "units": "seconds",
        "query": "SELECT max(COALESCE(ROUND(EXTRACT(epoch " +
                 "FROM now()-xact_start)),0)) as txn_time_max " +
                 "FROM pg_stat_activity WHERE xact_start IS NOT NULL;"
    },
    "pg_connections": {
        "description": "Number of connections",
        "units": "connctions",
        "query": "SELECT sum(numbackends) FROM pg_stat_database;"
    },
    "pg_wal_files": {
        "description": "number of wal files in pg_xlog directory",
        "units": "# wal files",
        "query": "SELECT count(*) AS wal_files FROM " +
                 "pg_ls_dir('pg_xlog') WHERE pg_ls_dir ~ E'^[0-9A-F]{24}$';"
    },
    "pg_xact_commit": {
        "description": "Transactions committed",
        "slope": "positive",
        "units": "transactions",
        "query": "SELECT sum(xact_commit) as xact_commit FROM " +
                 "pg_stat_database;",
    },
    "pg_xact_rollback": {
        "description": "Transactions rolled back",
        "slope": "positive",
        "units": "transactions",
        "query": "SELECT sum(xact_rollback) as xact_rollback FROM " +
                 "pg_stat_database;",
    },
    "pg_blks_read": {
        "description": "Blocks read",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(blks_read) as blks_read FROM " +
                 "pg_stat_database;",
    },
    "pg_blks_hit": {
        "description": "Blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(blks_hit) as blks_hit FROM " +
                 "pg_stat_database;",
    },
    "pg_tup_returned": {
        "description": "Tuples returned",
        "slope": "positive",
        "units": "tuples",
        "query": "SELECT sum(tup_returned) as tup_returned FROM " +
                 "pg_stat_database;",
    },
    "pg_tup_fetched": {
        "description": "Tuples fetched",
        "slope": "positive",
        "units": "tuples",
        "query": "SELECT sum(tup_fetched) as tup_fetched FROM " +
                 "pg_stat_database;",
    },
    "pg_tup_inserted": {
        "description": "Tuples inserted",
        "slope": "positive",
        "units": "tuples",
        "query": "SELECT sum(tup_inserted) as tup_inserted FROM " +
                 "pg_stat_database;",
    },
    "pg_tup_updated": {
        "description": "Tuples updated",
        "slope": "positive",
        "units": "tuples",
        "query": "SELECT sum(tup_updated) as tup_updated FROM " +
                 "pg_stat_database;",
    },
    "pg_tup_deleted": {
        "description": "Tuples deleted",
        "slope": "positive",
        "units": "tuples",
        "query": "SELECT sum(tup_deleted) as tup_deleted FROM " +
                 "pg_stat_database;",
    },
    "pg_heap_blks_read": {
        "description": "Heap blocks read",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(heap_blks_read) as heap_blks_read FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_heap_blks_hit": {
        "description": "Heap blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(heap_blks_hit) as heap_blks_hit FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_idx_blks_read_tbl": {
        "description": "Index blocks read",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(idx_blks_read) as idx_blks_read_tbl FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_idx_blks_hit_tbl": {
        "description": "Index blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(idx_blks_hit) as idx_blks_hit_tbl FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_toast_blks_read": {
        "description": "Toast blocks read",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(toast_blks_read) as toast_blks_read FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_toast_blks_hit": {
        "description": "Toast blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(toast_blks_hit) as toast_blks_hit FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_tidx_blks_read": {
        "description": "Toast index blocks read",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(tidx_blks_read) as tidx_blks_read FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_tidx_blks_hit": {
        "description": "Toast index blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(tidx_blks_hit) as tidx_blks_hit FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_tidx_blks_hit": {
        "description": "Toast index blocks hit",
        "slope": "positive",
        "units": "blocks",
        "query": "SELECT sum(tidx_blks_hit) as tidx_blks_hit FROM " +
                 "pg_statio_all_tables;",
    },
    "pg_bgwriter_buffers_checkpoint": {
        "description": "Buffers written at checkpoint",
        "slope": "positive",
        "units": "buffers",
        "query": "SELECT buffers_checkpoint FROM " +
                 "pg_stat_bgwriter;",
    },
    "pg_bgwriter_buffers_clean": {
        "description": "Buffers cleaned by bgwriter",
        "slope": "positive",
        "units": "buffers",
        "query": "SELECT buffers_clean FROM " +
                 "pg_stat_bgwriter;",
    },
    "pg_bgwriter_buffers_backend": {
        "description": "Buffers written by backends and not bgwriter",
        "slope": "positive",
        "units": "buffers",
        "query": "SELECT buffers_backend FROM " +
                 "pg_stat_bgwriter;",
    },
    "pg_bgwriter_buffers_alloc": {
        "description": "Buffers allocated globally",
        "slope": "positive",
        "units": "buffers",
        "query": "SELECT buffers_checkpoint FROM " +
                 "pg_stat_bgwriter;",
    },
}


def print_exception(custom_msg, exception):
    error_msg = custom_msg or "An error has occurred"
    print "%s %s" % (error_msg, exception),
    print "Code: %s, Message: %s" % (exception.pgcode, exception.pgerror)


class UpdateMetricThread(threading.Thread):
    def __init__(self, params):
        threading.Thread.__init__(self)
        self.running = False
        self.shuttingdown = False
        self.refresh_rate = 30
        self.host = "localhost"
        self.dbuser = "postgres"
        self.dbpass = "secret"
        self.database = "template1"
        self.port = 5432

        param_list = ["host", "port", "dbuser", "dbpass", "database",
                      "refresh_rate"]
        for attr in param_list:
            if attr in params:
                setattr(self, attr, params[attr])

    def shutdown(self):
        self.shuttingdown = True
        if not self.running:
            return
        self.join()

    def run(self):
        self.running = True

        while not self.shuttingdown:
            _Lock.acquire()
            try:
                self.update_metric()
            except psycopg2.OperationalError, e:
                print_exception("Unable to update metrics", e)
            _Lock.release()
            time.sleep(int(self.refresh_rate))

        self.running = False

    def update_metric(self):
        global metric_results
        try:
            conn = psycopg2.connect(host=self.host, port=self.port,
                                    database=self.database,
                                    user=self.dbuser, password=self.dbpass)
        except psycopg2.OperationalError, e:
            print_exception("Could not connect to database", e)
            raise

        converter = {
            'float': float,
            'uint': int
        }

        for metric_name, metric_attrs in metric_defs.iteritems():
            cur = conn.cursor()
            cur.execute(metric_attrs['query'])
            query_results = cur.fetchone()
            convert_fn = converter.get(
                metric_defs[metric_name].get('value_type'), int)
            metric_results[metric_name] = convert_fn(query_results[0])
            cur.close()

        conn.close()


def metric_init(params):
    global descriptors, Desc_Skel, _Worker_Thread

    _Worker_Thread = UpdateMetricThread(params)
    _Worker_Thread.start()

    for metric_desc in metric_defs:
        descriptors.append(create_desc(
            metric_desc, Desc_Skel, metric_defs[metric_desc]))

    return descriptors


def create_desc(metric_name, skel, prop):
    return dict(
        skel.items() +
        [('name', metric_name)] +
        [(k, v) for k, v in prop.items() if k in skel]
    )


def metric_cleanup():
    _Worker_Thread.shutdown()

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description='Debug the Ganglia PostgreSQL module.')
    parser.add_argument(
        '--host', default='localhost',
        help='The PostgreSQL database host (default: %(default)s).')
    parser.add_argument(
        '--port', type=int, default=5432,
        help='The PostgreSQL database network port (default: %(default)s).')
    parser.add_argument(
        '--dbuser', default='postgres',
        help='The PostgreSQL database user (default: postgres).')
    parser.add_argument(
        '--dbpass', default='secret',
        help='The PostgreSQL database password.(default: %(default)s). ' +
             'WARNING: Specifying passwords on the commandline is insecure. ' +
             'Consider the -W option.')
    parser.add_argument(
        '-W', dest='prompt_pass', action='store_true',
        help='Prompt for the PostgreSQL database password.')
    parser.add_argument(
        '--database', default='template1',
        help='The PostgreSQL database to use. (default: %(default)s).')
    parser.add_argument(
        '--refresh_rate', type=int, default=10,
        help='The interval, in seconds, between query executions ' +
             'metric collection. (default: %(default)s).')
    args = parser.parse_args()
    params = vars(args)
    if params['prompt_pass']:
        import getpass
        script_name = os.path.basename(__file__)
        params['dbpass'] = getpass.getpass(
            prompt="%s password: " % script_name)
    try:
        metric_init(params)
        while True:
            for d in descriptors:
                v = d['call_back'](d['name'])
                print ('value for %s is '+d['format']) % (d['name'],  v)
            print
            time.sleep(5)
    except KeyboardInterrupt:
        time.sleep(0.2)
        os._exit(1)
