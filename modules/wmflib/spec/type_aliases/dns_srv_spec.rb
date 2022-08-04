# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'Wmflib::DNS::Srv' do
  describe 'valid handling' do
    [
      '_etcd-server-ssl._tcp.exampl.org',
      '_jabber._udp.exampl.org',
      '_foo._dccp.exampl.org',
      '_bar._sctp.exampl.org',
      '_etcd-server-ssl._tcp.exampl.org',
      '_kerberos-master._tcp.example.com',
      ].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end

  describe 'invalid path handling' do
    context 'garbage inputs' do
      [
        '_ldap._tcp.dev._locations.example.com',
        'dev._locations.example.com',
        'example',
        'example.com',
        'www.example.com',
        [nil],
        [nil, nil],
        { 'foo' => 'bar' },
        {},
        '',
        "\nexample",
        "\nexample\n",
        "example\n",
        '2001:DB8::1',
        'www www.example.com',
      ].each do |value|
        describe value.inspect do
          it { is_expected.not_to allow_value(value) }
        end
      end
    end
  end
end
