#!/usr/bin/env python

# -*- coding: utf-8 -*-

# Copyright 2016 Eric Evans <eevans@wikimedia.org>, Wikimedia Foundation

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
Cassandra topk wide partition reports
"""


import argparse
import csv
import datetime
import getpass
import json
import operator
import re
import StringIO
import socket
import sys
import time
import logging

from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from subprocess import Popen, PIPE

try:
    import jsonschema
except ImportError:
    print >>sys.stderr, "Missing jsonschema module (Hint: apt-get install python-jsonschema)"
    sys.exit(1)

try:
    import requests
except ImportError:
    print >>sys.stderr, "Missing requests module (Hint: apt-get install python-requests)"
    sys.exit(1)

try:
    from jinja2 import Template
except ImportError:
    print >>sys.stderr, "Missing jinja2 module (Hint: apt-get install python-jinja2)"
    sys.exit(1)


class ElasticSearch(object):
    """Query elasticsearch."""
    page_size = 200

    def __init__(self, host, port=9200):
        self.host = host
        self.port = port

    def __url(self, index):
        return "http://{0.host}:{0.port}/{index}/_search".format(self, index=index)

    def search(self, index, query):
        """
        Executes an elasticsearch query of the given index; Returns a generator
        of objects from the hits array of the response.
        """
        if not isinstance(query, dict):
            raise RuntimeError("invalid argument; query must be a dictionary")
        query["from"] = 0
        query["size"] = ElasticSearch.page_size
        res = Page(requests.get(self.__url(index), data=json.dumps(query)))
        for hit in res.hits:
            yield hit
        for _ in range((res.total / ElasticSearch.page_size) + 1):
            query["from"] += len(res.hits)
            res = Page(requests.get(self.__url(index), data=json.dumps(query)))
            for hit in res.hits:
                yield hit


class Page(object):
    """
    Encapsulates a page of data as returned from elasticsearch.
    """
    response_schema = {
        "type": "object",
        "properties": {
            "timed_out": {
                "type": "boolean"
            },
            "hits": {
                "type": "object",
                "properties": {
                    "hits": {
                        "type": "array"
                    }
                },
                "required": ["hits"]
            }
        },
        "required": ["timed_out", "hits"]
    }

    def __init__(self, response):
        json_obj = Page.validate_response(response)
        self._total = json_obj["hits"]["total"]
        self._hits = json_obj["hits"]["hits"]

    @property
    def total(self):
        """
        Total number of results returned by query.
        """
        return self._total

    @property
    def hits(self):
        """
        Number of results in this page.
        """
        return self._hits

    @classmethod
    def validate_response(cls, response):
        """
        Validates the return status and JSON payload of a response returned by
        the requests module.
        """
        if not hasattr(response, "status_code"):
            raise Exception("invalid response object")
        if response.status_code != 200:
            raise Exception("elasticsearch returned status " +
                    "{0.status_code}: {1}".format(response, response.json()))
        json_obj = response.json()
        jsonschema.validate(json_obj, Page.response_schema)
        return json_obj


def search_query(cluster="eqiad"):
    """
    Returns the JSON-based elasticsearch query for Cassandra large partition
    warnings.
    """
    return {
        "query": {
            "bool": {
                "must": [
                    {"match": {
                        "logger_name": "org.apache.cassandra.io.sstable.format.big.BigTableWriter"
                    }},
                    {"match": {"cluster": cluster}},
                    {"match_phrase": {"message": "Writing large partition"}}
                ]
            }
        },
        "_source": ["message"]
    }


def index_names(days=7):
    """
    Returns a generator of logstash index names for the past N days.
    """
    def name(dt):
        return dt.strftime("logstash-%Y.%m.%d")
    now = datetime.datetime.now()
    yield name(now)
    for i in range(days):
        yield name(now - datetime.timedelta(days=i+1))


class EmailMessage(object):
    """
    An email report of the topk wide partition results.
    """
    text = """
    <html>
      <head>
        <style>
          th, td {
            text-align: left;
            padding: 0 1em 0 1em;
          }
          table {
            border-collapse: collapse;
          }
          table, th, td {
            border: 1px solid black;
          }
          p.notice {
            color: #777;
            font-size: 90%;
          }
        </style>
      </head>
      <body>
        <p>
          Respected Humans,
        </p>
        <p>
          Attached is a report of the top {{results|length}} widest partitions for the Cassandra
          cluster named <i>{{cluster_name}}</i>.
        </p>

        <table>
          <tr>
            <th>Size</th>
            <th>Partition</th>
          <tr>
        {% for result in results %}
          <tr>
            <td>{{result[1]}}</td>
            <td>{{result[0]}}</td>
          </tr>
        {% endfor %}
        </table>

        <h2>About this report:</h2>
        <p>
          Cassandra logs a warning whenever background compaction encounters a parition larger
          than the value of
          <a href="http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html">
            <code>compaction_large_partition_warning_threshold_mb</code>
          </a>.
          This report is periodically generated from an Elasticsearch query of these log messages,
          and emailed to {{email_address}}.
        </p>

        <table>
          <tr>
            <th>Execution host</th>
            <td>{{execution_host}}</td>
          </tr>
          <tr>
            <th>Logstash host</th>
            <td>{{logstash_host}}</td>
          </tr>
          <tr>
            <th>Execution time</th>
            <td>{{execution_time}} secs</td>
          </tr>
          <tr>
            <th>Query results</th>
            <td>{{total_query_results}}</td>
          </tr>
          <tr>
            <th>Unique partitions</th>
            <td>{{unique_query_results}}</td>
          </tr>
          <tr>
            <th>Cassandra cluster name</th>
            <td>{{cluster_name}}</td>
          </tr>
          <tr>
            <th>Source code</th>
            <td>https://github.com/eevans/services-adhoc-reports</td>
          </tr>
        </table>
      </body>
    </html>
    """

    def __init__(self, **kwargs):
        def __check_required_kwarg(kwarg, default=None):
            value = kwargs.get(kwarg, default)
            if not value:
                raise Exception("missing keyword argument: {}".format(kwarg))
            return value

        self.message = MIMEMultipart("alternative")
        self.message["Subject"] = __check_required_kwarg("subject")
        self.message["To"] = __check_required_kwarg("email_address")
        self.message["From"] = __check_required_kwarg("message_from")

        template_vars = {}
        template_vars["cluster_name"] = __check_required_kwarg("cluster_name")
        template_vars["logstash_host"] = __check_required_kwarg("logstash_host")
        template_vars["email_address"] = self.message["To"]
        template_vars["results"] = __check_required_kwarg("results")
        template_vars["execution_host"] = __check_required_kwarg("execution_host")
        template_vars["execution_time"] = __check_required_kwarg("execution_time")
        template_vars["total_query_results"] = __check_required_kwarg("total_query_results")
        template_vars["unique_query_results"] = __check_required_kwarg("unique_query_results")

        if not isinstance(template_vars["results"], list):
            raise Exception("invalid argument for keyword results (not a list)")

        self.template = Template(EmailMessage.text)
        self.message.attach(MIMEText(self.template.render(template_vars).encode("utf-8"), "html"))

    def send(self):
        """
        Deliver this report.
        """
        proc = Popen(["/usr/sbin/exim4", "-i", self.message["To"]],
                stdout=PIPE, stdin=PIPE, stderr=PIPE)
        proc.communicate(input=self.message.as_string())

    def attach(self, message):
        """
        Add an attachment to this report.
        """
        if not isinstance(message, MIMEBase):
            raise Exception("invalid message")
        self.message.attach(message)


def write_csv(stream, results):
    """
    Writes the results in CSV format to the specified stream
    """
    csv_writer = csv.writer(stream)
    for res in results:
        csv_writer.writerow([res[0].encode("utf-8"), res[1]])


def csv_attachement(results):
    """
    Return an email attachment of a csv file containing results.
    """
    csv_fp = StringIO.StringIO()
    write_csv(csv_fp, results)
    csv_msg = MIMEText(csv_fp.getvalue(), "csv")
    csv_msg.add_header("Content-Disposition", "attachment", filename="report.csv")
    return csv_msg


def local_hostname():
    """
    Returns the fully-qualified hostname of this current machine.
    """
    return socket.gethostbyaddr(socket.gethostname())[0]


def subject(days):
    """
    Returns a formated email subject line.
    """
    now = datetime.datetime.now()
    date_to = now.strftime("%Y-%m-%d")
    date_from = (now - datetime.timedelta(days=days)).strftime("%Y-%m-%d")
    return "Cassandra wide partition report: period of {} to {}".format(date_from, date_to)


def strfsize(num, suffix='B'):
    """
    Formats a size as a human-readable string.
    """
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi']:
        if abs(num) < 1024.0:
            return "%.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)


def pretty_print(values):
    """
    Writes the report as a pretty-formatted list on stdout
    """
    header = ['Size', 'Partition', 'Size (in bytes)']
    size = [len(x) for x in header]
    results = []
    # format the values and find out the largest element in each column
    for val in values:
        tup = (strfsize(val[1]), val[0], str(val[1]))
        for idx, slen in enumerate(size):
            if len(tup[idx]) > slen:
                size[idx] = len(tup[idx])
        results.append(tup)
    results.insert(0, header)
    # adjust the width of each cell
    results = [[res[idx].ljust(s) for idx, s in enumerate(size)] for res in results]
    # print it out
    for res in results:
        sys.stdout.write('%s  %s  %s\n' % (res[0], res[1], res[2]))


def send_email(values, args, count, exec_start_time):
    """
    Create and send the report in an e-mail
    """
    logging.warning("Sending email report...")
    # Craft an html email message report.
    email = EmailMessage(
        results=[(i[0], strfsize(i[1])) for i in values[:args.top]],
        subject=subject(args.last_days),
        email_address=args.email,
        message_from="{}@{}".format(getpass.getuser(), local_hostname()),
        cluster_name=args.cluster,
        logstash_host=args.logstash_host,
        execution_host=local_hostname(),
        execution_time=time.time()-exec_start_time,
        total_query_results=count,
        unique_query_results=len(values)
    )
    email.attach(csv_attachement(values[:args.top]))    # Attach a csv file.
    email.send()                                        # Deliver.
    logging.warning("Done.")


def parse_arguments():
    """
    Parse command-line arguments.
    """
    parser = argparse.ArgumentParser(
        description="Generate an email report of the widest Cassandra partitions.")
    parser.add_argument(
        "-e", "--email", metavar="ADDRESS", default='',
        help="Email the report to the specified address")
    parser.add_argument(
        '-s', '--csv', action='store_true',
        help='Output a comma-delimited report to stdout')
    parser.add_argument(
        "-H", "--logstash-host",
        metavar="HOST",
        default="logstash1001.eqiad.wmnet",
        help="Logstash hostname or address to search")
    parser.add_argument(
        "-p", "--logstash-port", metavar="PORT", type=int, default=9200,
        help="Logstash port number")
    parser.add_argument(
        "-k", "--top", metavar="N", type=int, default=50,
        help="Number of results to report")
    parser.add_argument(
        "-c", "--cluster", metavar="NAME", default="eqiad",
        help="Cassandra cluster name")
    parser.add_argument(
        "-d", "--last-days", metavar="DAYS", default=7, type=int,
        help="Past number of days to report on")
    return parser.parse_args()


def main():
    """
    Queries elasticsearch for matching records from all applicable daily indices.
    Generates an email report of the topk matching results and delivers it to
    the requested email address.
    """
    exec_start_time = time.time()
    args = parse_arguments()
    count = 0
    results = {}
    log_message_re = re.compile(
        r"Writing large partition (?P<partition>.+) \((?P<bytes>[\d]+) bytes\)")
    logstash = ElasticSearch(args.logstash_host, args.logstash_port)

    # Query each daily logstash index, for the last N days.
    for index in index_names(args.last_days):
        logging.warning("Querying elasticsearch index: %s" % index)
        try:
            # Collate the returned results.
            for hit in logstash.search(index, search_query(args.cluster)):
                count += 1
                message = hit["_source"]["message"]
                match = log_message_re.match(message)
                if not match:
                    logging.error("Result did not match regex (\"{}\")".format(message))
                    continue
                partition = match.group("partition")
                size = match.group("bytes")
                if results.get(partition, 0) < size:
                    results[partition] = int(size)
        # TODO: An exception is thrown when we page past `index.max_result_window` number of results
        # (an elasticsearch setting; 10000 in our environment).  The solution seems to be to use the
        # scroll API instead
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html
        except Exception, err:
            logging.error("Query of index {} failed: {}".format(index, err))

    # Sort results by partition size, descending.
    values = sorted(results.items(), key=operator.itemgetter(1), reverse=True)

    # decide on the action to perform
    if len(args.email):
        # send the e-mail
        send_email(values, args, count, exec_start_time)
    elif args.csv:
        # print the CSV on stdout
        write_csv(sys.stdout, values[:args.top])
    else:
        # pretty-print the results
        pretty_print(values[:args.top])


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stderr, level=logging.WARNING)
    main()
