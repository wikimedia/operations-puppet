import configparser
import csv
import os
import glob
# requires python3-pymysql
import pymysql
import re
import socket


class WMFMariaDB:
    """
    Wrapper class to connect to MariaDB instances within the Wikimedia
    Foundation cluster. It simplifys all authentication methods by providing a
    unique, clean way to do stuff on the databases.
    """

    connection = None
    host = None
    port = None
    database = None
    __debug = False

    @staticmethod
    def get_credentials(host, port, database):
        """
        Given a database instance, return the authentication method, including
        the user, password, socket and ssl configuration.
        """
        if host == 'localhost':
            # connnect to localhost using plugin_auth:
            mysql_sock = '/var/run/mysqld/mysqld.sock'
            ssl = None
            user = os.geteuid()
            password = None
            charset = None
        elif host.startswith('db'):
            # connect to a production remote host, use ssl
            config = configparser.ConfigParser(interpolation=None)
            config.read('/root/.my.cnf')
            user = config['client']['user']
            password = config['client']['password']
            ssl = {'ca': '/etc/ssl/certs/Puppet_Internal_CA.pem'}
            mysql_sock = None
            charset = None
        else:
            # connect to a labs remote host, use ssl
            config = configparser.ConfigParser(interpolation=None)
            config.read('/root/.my.cnf')
            user = config['labsdb']['user']
            password = config['labsdb']['password']
            if host.startswith('labsdb1001') or host.startswith('labsdb1003'):
                ssl = None
            else:
                ssl = {'ca': '/etc/ssl/certs/Puppet_Internal_CA.pem'}
            mysql_sock = None
            charset = None

        return (user, password, mysql_sock, ssl, charset)

    @property
    def debug(self):
        """debug getter"""
        return self.__debug

    @debug.setter
    def debug(self, debug):
        """debug setter"""
        if not debug:
            self.__debug = False
        else:
            self.__debug = True

    @staticmethod
    def resolve(host):
        """
        Return the full qualified domain name for a database hostname. Normally
        this return the hostname itself, except in the case where the
        datacenter and network parts have been omitted, in which case, it is
        completed as a best effort.
        """

        if '.' not in host and host != 'localhost':
            fqdn = socket.getfqdn()
            if '.' in fqdn and len(fqdn) > 1:
                domain = fqdn[fqdn.index('.'):]
                host = host + domain
        return host

    def __init__(self, host, port=3306, database=None, debug=False):
        """
        Try to connect to a mysql server instance and returns a python
        connection identifier, which you can use to send one or more queries.
        """

        self.debug = debug
        host = WMFMariaDB.resolve(host)
        (user, password, socket, ssl, charset) = WMFMariaDB.get_credentials(
            host, port, database)

        if self.debug:
            if host == 'localhost':
                address = '{}[socket={}]'.format(host, socket)
            else:
                address = '{}:{}'.format(host, port)
            print('Connecting to {}/{}'.format(address, database))
        try:
            self.connection = pymysql.connect(
                host=host, port=port, user=user, password=password,
                db=database, charset='utf8mb4', unix_socket=socket, ssl=ssl)
        except Exception:
            self.connection = None
        self.host = host
        self.port = int(port)
        self.database = database

    def change_database(self, database):
        """
        Changes the current database without having to disconnect and reconnect
        """
        # cursor = self.connection.cursor()
        # cursor.execute('use `{}`'.format(database))
        # cursor.close()
        if self.connection is None:
            print('ERROR: There is no connection active; could not change db')
            return
        try:
            self.connection.select_db(database)
        except Exception:
            return
        self.database = database
        if self.debug:
            print('Changed database to \'{}\''.format(self.database))

    def execute(self, command, dryrun=True):
        """
        Sends a single query to a previously connected server instance, returns
        if that query was successful, and the rows read if it was a SELECT
        """

        # TODO: Handle common errors correctly
        cursor = self.connection.cursor()
        try:
            if dryrun:
                print(("We will *NOT* execute \'{}\' on {}:{}/{} because"
                       "this is a dry run.").format(
                    command, self.host, self.port, self.database))
                cursor.execute('SELECT \'success\' as dryrun')
            else:
                if self.debug:
                    print('Executing \'{}\''.format(command))
                cursor.execute(command)
        except Exception:
            cursor.close()
            query = command
            host = self.host
            port = self.port
            database = self.database
            return {"query": query, "host": host, "port": port,
                    "database": database, "success": False}

        rows = None
        fields = None
        query = command
        host = self.host
        port = self.port
        database = self.database
        if cursor.rowcount > 0:
            rows = cursor.fetchall()
            fields = tuple([x[0] for x in cursor.description])
        numrows = cursor.rowcount
        cursor.close()

        return {"query": query, "host": host, "port": port,
                "database": database, "success": True, "numrows": numrows,
                "rows": rows, "fields": fields}

    @staticmethod
    def get_wikis(shard=None, wiki=None):
        """
        Returns a tuple of hosts, ports and database names for all wikis from
        the given shard. If shard is the string 'ALL', return all wikis from
        all servers. The returned list is ordered by instance- that means,
        wikis from the same instance are grouped together.

        Currently implemented with shard lists on disk, this logic should be
        simplified in the future with a dynamic database. The following assumes
        there are not repeated shards/hosts (except in the same instance has
        more than one shard), so no virtual dblists or hosts files.
        """
        if shard == 'ALL':
            # do a recursive call for every shard found
            wiki_list = []
            shard_dblists = glob.glob('*.dblist')
            for file in shard_dblists:
                shard = re.search(r'([^/]+)\.dblist', file).group(1)
                wiki_list += WMFMariaDB.get_wikis(shard=shard, wiki=wiki)
            return wiki_list
        elif shard is None and wiki is None:
            # No shards or wikis selected, return the empty list
            print('No wikis selected')
            return list()
        elif shard is None and wiki is not None:
            # TODO: shard is not set, search the shard for a wiki
            dbs = [wiki]
            shard_dblists = glob.glob('*.dblist')
            for file in shard_dblists:
                shard_dbs = []
                with open(file, 'r') as f:
                    shard_dbs = f.read().splitlines()
                # print('{}: {}'.format(file, shard_dbs))
                if wiki in shard_dbs:
                    shard = re.search(r'([^/]+)\.dblist', file).group(1)
                    break
            if shard is None or shard == '':
                print('The wiki \'{}\' wasn\'t found on any shard'.format(
                    wiki))
                return list()
        elif shard is not None and wiki is not None:
            # both shard and wiki are set, check the wiki is really on the
            # shard
            shard_dbs = []
            with open('{}.dblist'.format(shard), 'r') as f:
                shard_dbs = f.read().splitlines()
            if wiki not in shard_dbs:
                print("The wiki '{}' wasn't found on the shard '{}'".format(
                    wiki, shard))
                return list()
            dbs = [wiki]
        else:
            # shard is set, but not wiki, get all dbs from that shard
            dbs = []
            with open('{}.dblist'.format(shard), 'r') as f:
                dbs = f.read().splitlines()

        with open('{}.hosts'.format(shard), 'r') as f:
            hosts = list(csv.reader(f, delimiter='\t'))

        # print(hosts)
        # print(dbs)

        return sorted([([h[0], int(h[1])] + [d]) for h in hosts for d in dbs])

    @staticmethod
    def execute_many(command, shard=None, wiki=None, dryrun=True, debug=False):
        """
        Executes a command on all wikis from the given shard, once per
        instance, serially. If dryrun is True, not execute, but connect and
        print what would be done.
        """
        result = []
        connection = None
        dblist = WMFMariaDB.get_wikis(shard=shard, wiki=wiki)

        for host, port, database in dblist:
            if (connection is not None and connection.host == host
                    and connection.port == port
                    and connection.database != database):
                connection.change_database(database)
                if connection.database != database:
                    print('Could not change to database {}'. format(database))
                    continue
            else:
                if connection is not None:
                    connection.disconnect()
                connection = WMFMariaDB(host=host, port=port,
                                        database=database, debug=debug)

            if connection.connection is None:
                print('ERROR: Could not connect to {}:{}/{}'.format(host, port,
                                                                    database))
                resultset = None
            else:
                resultset = connection.execute(command, dryrun)

            if resultset is None:
                result.append({"success": False, "host": host, "port": port,
                               "database": database, "numrows": 0,
                               "rows": None, "fields": None})
            else:
                result.append(resultset)

        if connection.connection is not None:
            connection.disconnect()
        return result

    def disconnect(self):
        """
        Ends the connection to a database, freeing resources. No more queries
        will be able to be sent to this connection id after this is executed
        until a new connection is open.
        """
        if self.debug:
            print('Disconnecting from {}:{}/{}'.format(self.port, self.host,
                                                       self.database))
        if self.connection is not None:
            self.connection.close()
            self.connection = None
