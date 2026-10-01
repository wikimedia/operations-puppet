# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "puppetdb::query_facts" do
  describe "one fact" do
    let(:pre_condition) do
      "function wmflib::puppetdb_query($pql) {
        [{
          'certname'        => 'foo',
          'facts.networking.ip' => '192.0.2.42'
        }]
      }"
    end
    it do
      is_expected.to run.with_params(["facts.networking.ip"]).and_return(
        { "foo" => { "facts.networking.ip" => "192.0.2.42" } }
      )
    end
  end
  describe "multiple fact" do
    let(:pre_condition) do
      "function wmflib::puppetdb_query($pql) {
        [{
          'certname'        => 'foo',
          'facts.networking.ip' => '192.0.2.42',
          'facts.networking.fqdn'      => 'foo.example.com',
          'facts.os.family'    => 'Linux',
        }]
      }"
    end
    it do
      is_expected.to run.with_params(
        %w[facts.networking.ip facts.networking.fqdn facts.os.family]
      ).and_return(
        {
          "foo" => {
            "facts.networking.ip" => "192.0.2.42",
            "facts.networking.fqdn" => "foo.example.com",
            "facts.os.family" => "Linux"
          }
        }
      )
    end
  end
  describe "multiple hosts" do
    let(:pre_condition) do
      "function wmflib::puppetdb_query($pql) {
        [
          {
            'certname'         => 'sretest1006.eqiad.wmnet',
            'facts.networking.ip6' => 'fe80::4819:64ff:fe7f:805a',
          },
          {
            'certname'         => 'sretest1005.eqiad.wmnet',
            'facts.networking.ip6' => 'fe80::c3f:24ff:fec4:d3ed',
          }
        ]
      }"
    end
    it do
      is_expected.to run.with_params(
        %w[facts.networking.ip6],
        'certname in ["sretest1005.eqiad.wmnet","sretest1006.eqiad.wmnet"]'
      ).and_return(
        {
          "sretest1006.eqiad.wmnet" => {
            "facts.networking.ip6" => "fe80::4819:64ff:fe7f:805a"
          },
          "sretest1005.eqiad.wmnet" => {
            "facts.networking.ip6" => "fe80::c3f:24ff:fec4:d3ed"
          }
        }
      )
    end
  end
end
