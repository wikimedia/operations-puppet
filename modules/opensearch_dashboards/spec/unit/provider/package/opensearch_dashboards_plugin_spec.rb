# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../../../rake_modules/spec_helper'

describe Puppet::Type.type(:package).provider(:opensearch_dashboards_plugin) do
  include PuppetlabsSpec::Fixtures

  let(:execute_options) do
    { failonfail: true, combine: true, custom_environment: {} }
  end
  let(:installed_plugins) { File.read(my_fixture('plugin-list.txt')) }
  let(:osd_plugin_executable) { '/usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin' }

  before(:each) { allow(Puppet::Util).to receive(:which).with(osd_plugin_executable).and_return(osd_plugin_executable) }
  describe 'plugin' do
    let(:name) { 'securityDashboards' }

    let(:resource) do
      Puppet::Type.type(:package).new(
        name: name,
        provider: :opensearch_dashboards_plugin,
      )
    end

    let(:provider) do
      provider = described_class.new
      provider.resource = resource
      provider
    end

    describe 'provider features' do
      it { is_expected.to be_upgradeable }
      it { is_expected.to be_versionable }
      it { is_expected.to be_installable }
      it { is_expected.to be_uninstallable }
    end

    context 'state' do
      it 'instances method parses process output' do
        allow(Puppet::Util::Execution).to receive(:execute).with(' --allow-root list').and_return(installed_plugins)
        packages = described_class.instances.map { |package| package.properties }
        expected = [
          { name: 'alertingDashboards',          ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'anomalyDetectionDashboards',  ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'customImportMapDashboards',   ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'ganttChartDashboards',        ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'indexManagementDashboards',   ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'mlCommonsDashboards',         ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'notificationsDashboards',     ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'observabilityDashboards',     ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'queryWorkbenchDashboards',    ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'reportsDashboards',           ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'searchRelevanceDashboards',   ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'securityAnalyticsDashboards', ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
          { name: 'securityDashboards',          ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin },
        ]
        expect(packages).to eq(expected)
      end
      it 'query method returns a value' do
        allow(Puppet::Util::Execution).to receive(:execute).with(' --allow-root list').and_return(installed_plugins)
        expected = { name: 'securityDashboards', ensure: '2.6.0.0', provider: :opensearch_dashboards_plugin }
        expect(provider.query).to eq(expected)
      end
    end

    context 'not installed' do
      before(:each) do
        provider.instance_variable_get('@property_hash')[:ensure] = :absent
      end

      it 'will ensure present from a file' do
        resource[:ensure] = :present
        resource[:source] = '/foo/bar/bazPlugin-1.0.0.zip'
        expect(provider).to receive(:execute).with(array_including('file:///foo/bar/bazPlugin-1.0.0.zip'))
        provider.install
      end

      it 'will ensure latest from a file' do
        resource[:ensure] = :latest
        resource[:source] = '/foo/bar/bazPlugin-1.0.0.zip'
        expect(provider).to receive(:execute).with(array_including('file:///foo/bar/bazPlugin-1.0.0.zip'))
        provider.install
      end

      it 'will ensure present from a url' do
        resource[:ensure] = :present
        resource[:source] = 'http://a.web.site/repository/bazPlugin-1.0.0.zip'
        expect(provider).to receive(:execute).with(array_including('http://a.web.site/repository/bazPlugin-1.0.0.zip'))
        provider.install
      end

      it 'will ensure latest from a url' do
        resource[:ensure] = :latest
        resource[:source] = 'http://a.web.site/repository/bazPlugin-1.0.0.zip'
        expect(provider).to receive(:execute).with(array_including('http://a.web.site/repository/bazPlugin-1.0.0.zip'))
        provider.install
      end

      it 'cannot ensure present when source is a repo' do
        resource[:ensure] = :present
        resource[:source] = 'http://a.web.site/repository'
        expect { provider.install }.to raise_error(ArgumentError)
      end

      it 'cannot ensure latest when source is a repo' do
        resource[:ensure] = :latest
        resource[:source] = 'http://a.web.site/repository'
        expect { provider.install }.to raise_error(ArgumentError)
      end
    end

    context 'installed' do
      before(:each) do
        provider.instance_variable_get('@property_hash')[:ensure] = '2.6.0.0'
      end

      it 'will uninstall before install' do
        resource[:ensure] = :latest
        resource[:source] = '/foo/bar/securityDashboards-2.7.0.0.zip'
        expect(provider).to receive(:execute).twice.with(array_including(%r{remove|install}))
        provider.update
      end

      it 'will extract latest version from source' do
        resource[:ensure] = :latest
        resource[:source] = '/foo/bar/securityDashboards-2.5.0.0.zip'
        expect(provider.latest).to eq('2.5.0.0')
      end
    end

    context 'remove' do
      it 'will uninstall' do
        resource[:ensure] = :absent
        expect(provider).to receive(:execute).with(array_including('remove'))
        provider.uninstall
      end
    end
  end
end
