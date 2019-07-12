# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9', '10'],
    }
  ]
}

describe 'monitoring::check_prometheus' do
  let(:pre_condition) do
    "class profile::base ( $notifications_enabled = 1 ){}
    include profile::base"
  end
  let(:title) { 'foobar' }
  let(:facts) { {} }
  let(:params) do
    {
      description: 'test',
      query: 'test',
      prometheus_url: 'http://prom.example.org/',
      warning: 1,
      critical: 2,
      dashboard_links: ['https://grafana.wikimedia.org/test'],
      # method: "ge",
      # nan_ok: false,
      # check_interval: "1",
      # retry_interval: "1",
      # retries: "5",
      # group: :undef,
      # ensure: "present",
      # nagios_critical: false,
      # contact_group: "admins",
      # notes_link: "https://wikitech.wikimedia.org/wiki/Monitoring/Missing_notes_link",
    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # let (:pre_condition) { "class {'::foobar' }" }

  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_monitoring__service('foobar').with(
            ensure: 'present',
            description: 'test',
            check_command: 'check_prometheus!http://prom.example.org/!test!1!2!foobar!ge',
            retries: '5',
            check_interval: '1',
            retry_interval: '1',
            group: nil,
            critical: false,
            contact_group: 'admins',
            notes_url: [
              # The quoting here is intentional because ... nagios code
              "'https://wikitech.wikimedia.org/wiki/Monitoring/Missing_notes_link' " +
              "'https://grafana.wikimedia.org/test'"
            ]
          )
        end
      end
      describe 'Change Defaults' do
        context 'nan_ok' do
          before { params.merge!(nan_ok: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_monitoring__service('foobar').with_check_command(
              'check_prometheus_nan_ok!http://prom.example.org/!test!1!2!foobar!ge'
            )
          end
        end
        context 'group' do
          before { params.merge!(group: 'foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_monitoring__service('foobar').with_group('foobar') }
        end
        context 'query escaped !' do
          before { params.merge!(query: 'query(\!value)') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_monitoring__service('foobar').with_check_command(
              'check_prometheus!http://prom.example.org/!query(\\!value)!1!2!foobar!ge'
            )
          end
        end
        context 'query escaped !' do
          before { params.merge!(query: 'query(\\!value)') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_monitoring__service('foobar').with_check_command(
              'check_prometheus!http://prom.example.org/!query(\\!value)!1!2!foobar!ge'
            )
          end
        end
      end
      describe 'check bad parameters' do
        context 'query unescaped exclamation mark (!)' do
          before { params.merge!(query: 'query(!value)') }
          it do
            is_expected.to raise_error(
              Puppet::Error,
              /All exclamation marks in the query parameter must be escaped e.g. \\!/
            )
          end
        end
        context 'dashboard_links incorrect endpoint' do
          before { params.merge!(dashboard_links: ['http://example.org']) }
          it do
            is_expected.to raise_error(
              Puppet::Error,
              %r{Pattern\[/\^https:\\/\\/grafana\\\.wikimedia\\\.org/\]}
            )
          end
        end
        context 'dashboard_links no links provided' do
          before { params.merge!(dashboard_links: []) }
          it do
            is_expected.to raise_error(
              Puppet::Error,
              /expects size to be at least 1, got 0/
            )
          end
        end
        context 'dashboard_links' do
          before { params.merge!(dashboard_links: ['http:example.org']) }
          it do
            is_expected.to raise_error(
              Puppet::Error,
              %r{Pattern\[/\^https:\\/\\/grafana\\\.wikimedia\\\.org/\]}
            )
          end
        end
      end
    end
  end
end
