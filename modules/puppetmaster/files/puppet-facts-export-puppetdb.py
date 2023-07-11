#!/usr/bin/python3
import configparser
import os
import shutil
import subprocess
import tempfile

from datetime import datetime, timedelta

import requests
import yaml
import urllib3


urllib3.disable_warnings(urllib3.exceptions.SubjectAltNameWarning)


class PuppetDBApiError(Exception):
    """Used to raise errors from the puppetapi."""


# TODO: switch to pypuppetdb
class PuppetDBApi(object):
    """Simple class to fetch nodes from puppetdb."""
    def __init__(self, puppetdb_config_file):
        config = configparser.ConfigParser()
        config.read(puppetdb_config_file)
        # TODO: add support for multiple urls
        self.server_url = config['main']['server_urls'].split(',')[0]
        self._cacert = None
        self._key = None
        self._cert = None

    @staticmethod
    def _puppet_config(config: str, section: str = 'agent') -> str:
        """Use puppet to retrieve a config setting.

        Arguments
            config: the config item to fetch

        """
        command = ['puppet', 'config', 'print', '--section', section, config]
        try:
            result = subprocess.run(command, capture_output=True, check=True)
        except subprocess.CalledProcessError as error:
            raise PuppetDBApiError(
                f"unable to get puppet config {config} from {section} section"
            ) from error
        return result.stdout.decode().strip()

    @property
    def cacert(self):
        """Property to return the cacert."""
        if self._cacert is None:
            self._cacert = self._puppet_config('localcacert')
        return self._cacert

    @property
    def key(self):
        """Property to return the puppet private key."""
        if self._key is None:
            self._key = self._puppet_config('hostprivkey')
        return self._key

    @property
    def cert(self):
        """Property to return the puppet public certificate."""
        if self._cert is None:
            self._cert = self._puppet_config('hostcert')
        return self._cert

    def url_for(self, endpoint):
        """Return the url for a specific endpoint."""
        return '{url}/pdb/query/v4/{ep}'.format(url=self.server_url, ep=endpoint)

    def get(self, endpoint):
        """Get the specific endpoint."""
        return requests.get(
            self.url_for(endpoint),
            verify=self.cacert,
            cert=(self.cert, self.key)
        ).json()


def main():
    """Main entry point."""
    date_format = '%Y-%m-%d %H:%M:%S.%s +00:00'
    datetime_facts = datetime.utcnow()
    timestamp = datetime_facts.strftime(date_format)
    exp = (datetime_facts + timedelta(days=365)).strftime(date_format)

    outfile = '/tmp/puppet-facts-export.tar.xz'
    tmpdir = tempfile.mkdtemp(dir='/tmp', prefix='puppetdb-export')
    factsdir = os.path.join(tmpdir, 'yaml', 'facts')
    print("Saving facts to {}".format(factsdir))
    os.makedirs(factsdir)
    conf = os.environ.get('PUPPETDB_CONFIG_FILE', '/etc/puppet/puppetdb.conf')
    pdb = PuppetDBApi(conf)
    for i, node in enumerate(pdb.get('nodes')):
        if node.get('deactivated', True) is not None:
            continue
        nodename = node['certname']
        yaml_data = {}
        facts = pdb.get('nodes/{}/facts'.format(nodename))
        if not facts:
            continue
        for fact in facts:
            yaml_data[fact['name']] = fact['value']
        filename = os.path.join(factsdir, "{}.yaml".format(nodename))
        # Anonymize potentially reserved data
        yaml_data['uniqueid'] = '43434343'
        yaml_data['boardserialnumber'] = '4242'
        yaml_data['boardproductname'] = '424242'
        yaml_data['serialnumber'] = '42424242'
        del yaml_data['trusted']
        with open(filename, 'w') as filehandle:
            contents = yaml.dump({'name': nodename, 'values': yaml_data,
                                  'timestamp': timestamp, 'expiration': exp})
            filehandle.write('--- !ruby/object:Puppet::Node::Facts\n' + contents)
        if i % 25 == 0:
            print('Wrote {} hosts...'.format(i))
    subprocess.check_call(['tar', 'cJvf', outfile, '--directory', tmpdir, 'yaml'])
    print('Facts exported to {}'.format(outfile))
    shutil.rmtree(tmpdir)


if __name__ == '__main__':
    main()
