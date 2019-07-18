# frozen_string_literal: true

require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9', '10'],
    }
  ]
}

describe 'puppetmaster::web_frontend' do
  # The title must match the fqdn used by
  # rspec to avoid caring about secrets
  let(:title) { 'foo.example.com' }
  let(:facts) { {} }
  let(:params) do
    {
      workers: [
        {'worker' => 'load20.example.com', 'loadfactor' => 20},
        {'worker' => 'load10.example.com', 'loadfactor' => 10},
        {'worker' => 'offline_load20.example.com', 'loadfactor' => 20, 'offline' => true},
        {'worker' => 'canary_load20.example.com', 'loadfactor' => 20, 'canary' => true},
        {'worker' => 'canary_load10.example.com', 'loadfactor' => 10, 'canary' => true},
        {'worker' => 'canary_offline_load20.example.com', 'loadfactor' => 20,
         'offline' => true, 'canary' => true},
      ],
      master: 'puppetmaster',
      # bind_address: "*",
      # priority: "90",
      # alt_names: :undef,
      # cert_secret_path: "puppetmaster",
      # ssl_ca_revocation_check: :undef,
      # canary_hosts: [],

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
          is_expected.to contain_apache__site('foo.example.com').with(
            ensure: 'present',
            priority: '90'
          ).with_content(
            %r{ProxyPass\s+/\s+balancer://backend/
            \s+<Proxy\s+balancer://backend>
            \s+BalancerMember\s+https://load20.example.com:8141\s+ping=1\sconnectiontimeout=1\s+retry=500\s+timeout=900\s+loadfactor=20
            \s+BalancerMember\s+https://load10.example.com:8141\s+ping=1\sconnectiontimeout=1\s+retry=500\s+timeout=900\s+loadfactor=10
            \s+Require\s+all\s+granted
            }x
          ).without_content(
            /SetEnvIf\s+Remote_Host/
          ).without_content(
            /offline_load20.example.com|canary_load[12]0.example.com|CANARY|canarybackend/
          )
        end
      end
      describe 'test canary hosts' do
        context 'Add some canary hosts' do
          before(:each) do
            params.merge!(
              canary_hosts: [
                'www.example.org', # This test hard codes the A/AAAA answers below
                'nxdomain.example.org', # It may make more senses to use resources we control
              ]
            )
          end
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_apache__site('foo.example.com').with(
              ensure: 'present',
              priority: '90'
            ).with_content(
              %r{SetEnvIf\s+Remote_Addr\s+2606:2800:220:1:248:1893:25C8:1946\s+CANARY=yes
              \s+SetEnvIf\s+Remote_Addr\s+93\.184\.216\.34\s+CANARY=yes
              \s+ProxyPass\s+/\s+balancer://canarybackend/\s+env=CANARY
              \s+<Proxy\s+balancer://canarybackend>
              \s+BalancerMember\s+https://canary_load20.example.com:8141\s+ping=1\sconnectiontimeout=1\s+retry=500\s+timeout=900\s+loadfactor=20
              \s+BalancerMember\s+https://canary_load10.example.com:8141\s+ping=1\sconnectiontimeout=1\s+retry=500\s+timeout=900\s+loadfactor=10
              \s+Require\s+all\s+granted}x
            ).with_content(
              %r{ProxyPass\s+/\s+balancer://backend/
              \s+<Proxy\s+balancer://backend>
              \s+BalancerMember\s+https://load20.example.com:8141\s+ping=1\sconnectiontimeout=1\s+retry=500\s+timeout=900\s+loadfactor=20
              \s+BalancerMember\s+https://load10.example.com:8141\s+ping=1\sconnectiontimeout=1\s+retry=500\s+timeout=900\s+loadfactor=10
              \s+Require\s+all\s+granted}x
            ).without_content(
              /offline_load20.example.com|canary_offline_load20.example.com/
            )
          end
        end
      end
    end
  end
end
