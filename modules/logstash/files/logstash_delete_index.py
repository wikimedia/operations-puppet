#!/usr/bin/env python

import argparse
import logging
import sys

from datetime import datetime, timedelta

import requests

from requests import HTTPError

logging.basicConfig(level=logging.WARN)
logger = logging.getLogger('ESCleanup')


class ESCleanup(object):

    def __init__(self, base_url='http://localhost:9200'):
        self.base_url = base_url

    def cleanup(self, prefix, before):
        for idx in self.indices():
            if self.should_delete(idx, prefix, before):
                try:
                    self.delete(idx)
                except HTTPError:
                    logger.exception('Could not delete index %s', idx)

    def should_delete(self, index, prefix, before):
        """ Check if an index should be deleted
        >>> c = ESCleanup()
        >>> c.should_delete('logstash-2017.01.01', 'logstash', date(2017, 05, 01))
        True
        >>> c.should_delete('logstash-2017.05.01', 'logstash', date(2017, 05, 01))
        False
        >>> c.should_delete('logstash-2017.06.01', 'logstash', date(2017, 05, 01))
        False
        >>> c.should_delete('other-prefix-2017.06.01', 'logstash', date(2017, 05, 01))
        False
        >>> c.should_delete('logstash-xxxxxx', 'logstash', date(2017, 05, 01))
        False
        """
        try:
            index_date = datetime.strptime(index, '{prefix}-%Y.%m.%d'.format(prefix=prefix)).date()
            return index_date < before
        except ValueError:
            logger.info('index %s does not follow the given format', index)
            return False

    def indices(self):
        response = requests.get(self.base_url + '/_cat/indices?h=index')
        response.raise_for_status()
        return response.text.splitlines()

    def delete(self, index):
        requests.delete(self.base_url + '/' + index).raise_for_status()


def parse_args(argv):
    """ parse program arguments
    >>> parse_args(['--max-age', '15', '--base-url', 'http://my.server.domain:9200',
    ... '--prefix', 'my-prefix'])
    Namespace(base_url='http://my.server.domain:9200', max_age=15, prefix='my-prefix')
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--base-url', default='http://localhost:9200',
                        help='the base URL to connect to elasticsearch server')
    parser.add_argument('--prefix', default='logstash',
                        help='the prefix identifying the logstash indices')
    parser.add_argument('--max-age', default=31, type=int,
                        help='indices will be kept for max-age days, older ones will be deleted')
    return parser.parse_args(argv)


if __name__ == '__main__':
    args = parse_args(sys.argv)
    before = datetime.today().date() - timedelta(days=args.max_age)
    ESCleanup(args.base_url).cleanup(args.prefix, before)
