from dateutil.parser import parse
import argparse
import logging
import re
import requests
from requests import HTTPError
import sys

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ESCleanup")


class ESCleanup(object):

    def __init__(self, base_url='http://localhost:9200'):
        self.base_url = base_url
        self.date_regex = re.compile('\d{4}\.\d{2}\.\d{2}')

    def cleanup(self, prefix, before):
        for idx in self.filter_to_delete(prefix, before, self.indices()):
            try:
                self.delete(idx)
            except HTTPError:
                logging.exception("Could not delete index %s", idx)

    def filter_to_delete(self, prefix, before, indices):
        """ Filter a list of indices to select the ones to delete
        >>> c = ESCleanup()
        >>> c.filter_to_delete(
        ... 'log',
        ... parse('2017.05.01'),
        ... ['log-2017.05.01', 'log-2017.04.15', 'log-2017.05.02', 'log-foo', 'foo'])
        ['log-2017.04.15']
        """
        return filter(lambda idx: self.should_delete(idx, prefix, before), indices)

    def should_delete(self, index, prefix, before):
        """ Check if an index should be deleted
        >>> c = ESCleanup()
        >>> c.should_delete('logstash-2017.01.01', 'logstash', parse('2017.05.01'))
        True
        >>> c.should_delete('logstash-2017.06.01', 'logstash', parse('2017.05.01'))
        False
        >>> c.should_delete('other-prefix-2017.06.01', 'logstash', parse('2017.05.01'))
        False
        >>> c.should_delete('logstash-xxxxxx', 'logstash', parse('2017.05.01'))
        False
        """
        try:
            return index.startswith(prefix) and self.extract_date(index) < before
        except ValueError:
            logger.warn("Could not find date in %s", index)
            return False

    def indices(self):
        response = requests.get(self.base_url + '/_cat/indices?h=index')
        response.raise_for_status()
        return response.text.splitlines()

    def extract_date(self, index):
        """ Extract a date in the format YYYY.mm.dd from an index name

        >>> c = ESCleanup()
        >>> c.extract_date('logstash-2017.01.02')
        datetime.datetime(2017, 1, 2, 0, 0)
        >>> c.extract_date('2017.03.04')
        datetime.datetime(2017, 3, 4, 0, 0)
        >>> c.extract_date('logstash-2017.05.06-suffix')
        datetime.datetime(2017, 5, 6, 0, 0)
        >>> c.extract_date('non-date')
        Traceback (most recent call last):
        ...
        ValueError: No date found in non-date
        """
        search = self.date_regex.search(index)
        if search:
            return parse(search.group())
        raise ValueError("No date found in {}".format(index))

    def delete(self, index):
        requests.delete(self.base_url + '/' + index).raise_for_status()


def parse_args(argv):
    """ parse program arguments
    >>> parse_args([])
    Traceback (most recent call last):
    ...
    SystemExit: 2
    >>> parse_args(['--date', '2017.05.01', '--base-url', 'http://my.server.domain:9200',
    ... '--prefix', 'my-prefix'])
    Namespace(base_url='http://my.server.domain:9200', date='2017.05.01', prefix='my-prefix')
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default='http://localhost:9200',
                        help='the base URL to connect to elasticsearch server')
    parser.add_argument("--prefix", default='logstash',
                        help='the prefix identifying the logstash indices')
    parser.add_argument("--date", required=True,
                        help='indices older than this date will be deleted')
    return parser.parse_args(argv)


if __name__ == "__main__":
    args = parse_args(sys.argv)
    ESCleanup(args.base_url).cleanup(args.prefix, parse(args.date))
