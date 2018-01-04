require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'httpd::conf' do
  let(:pre_condition){ 'service { "apache2": ensure => running }'}
  let(:title) { 'foobar' }
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      context 'with default parameters' do
        let(:params) { {'content' => 'hello, world'} }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/apache2/conf-available/50-foobar.conf')
                              .with_ensure('present')
                              .with_content("hello, world\n")
                              .that_notifies('Service[apache2]')
        }
        it { is_expected.to contain_file('/etc/apache2/conf-enabled/50-foobar.conf')
                              .with_ensure('link')
                              .with_target('/etc/apache2/conf-available/50-foobar.conf')
                              .that_notifies('Service[apache2]')
        }
      end

      context 'when absented' do
        let(:params) { {'ensure' => 'absent'} }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/apache2/conf-available/50-foobar.conf')
                              .with_ensure('absent')
                              .that_notifies('Service[apache2]')
        }
        it { is_expected.to contain_file('/etc/apache2/conf-enabled/50-foobar.conf')
                              .with_ensure('absent')
                              .that_notifies('Service[apache2]')
        }
      end
      context 'when replacing a file' do
        let(:params) { {'content' => 'hello, world', 'replaces' => 'ports.conf' } }
        it { is_expected.to contain_file('foobar_ports.conf')
                              .with_path('/etc/apache2/ports.conf')
                              .with_ensure('absent')
        }
      end
      context 'when setting up a virtualhost' do
        let(:params) { {'content' => 'hello, world', 'conf_type' => 'sites', 'priority' => 8 } }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/apache2/sites-available/08-foobar.conf')}
      end
      context 'when setting up an environment variable' do
        let(:params) { {'content' => 'FOO=bar', 'conf_type' => 'env'} }
        it { is_expected.to contain_file('/etc/apache2/env-available/50-foobar.sh')
                              .with_content("FOO=bar\n")}
      end
    end
  end
end
