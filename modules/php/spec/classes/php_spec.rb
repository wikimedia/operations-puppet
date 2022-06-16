# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'php' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    let(:params) {{'versions' => ['7.2']}}
    context "on #{os}" do
      let(:facts) { facts }
      context 'default parameters' do
        it { is_expected.to compile }

        it { is_expected.to contain_class('php::default_extensions') }
        it { is_expected.to contain_package('php7.2-cli') }
        it { is_expected.to contain_file('/etc/php/7.2/cli/conf.d')
          .with_mode('0755').with_ensure('directory')
          .with_owner('root').with_group('root')
        }
        it { is_expected.to contain_file('/etc/php/7.2/cli/php.ini')
          .with_mode('0444')
          .with_owner('root')
          .with_group('root')
          .with_content(/^mysql.connect_timeout = 1/)
        }
      end
      context 'non-default PHP version' do
        let(:params) { super().merge({ 'versions' => ['7.3'] })}
        it { is_expected.to compile }
        it { is_expected.to contain_package('php7.3-cli') }
        it { is_expected.to contain_file('/etc/php/7.3/cli/conf.d')
          .with_mode('0755').with_ensure('directory')
          .with_owner('root').with_group('root')
          .with_recurse(true)
          .with_purge(true)
        }
        it { is_expected.to contain_file('/etc/php/7.3/cli/php.ini')
          .with_mode('0444')
          .with_owner('root')
          .with_group('root')
          .with_content(/^mysql.connect_timeout = 1/)
        }
      end

      context 'more than one sapi' do
        let(:params) do
          super().merge({
            'sapis' => ['cli', 'fpm']
          })
        end
        it { is_expected.to compile }

        it { is_expected.to contain_class('php::default_extensions') }
        it { is_expected.to contain_package('php7.2-cli') }
        it { is_expected.to contain_package('php7.2-fpm') }
        it { is_expected.to contain_file('/etc/php/7.2/fpm/conf.d')
          .with_mode('0755').with_ensure('directory')
          .with_owner('root').with_group('root')
        }
        it { is_expected.to contain_file('/etc/php/7.2/fpm/php.ini')
          .with_mode('0444')
          .with_owner('root')
          .with_group('root')
          .with_content(/^mysql.connect_timeout = 1/)
        }
      end
      context 'configuring extensions' do
        let(:params) do
          super().merge({
            'extensions' => {
              'igbinary' => {'versioned_packages' => true, 'ensure' => 'absent'},
              'mysqlnd'  => {'config' => {'mysql.persistent_connections' => false}}
            }
          })
        end
        it { is_expected.to compile }

        it { is_expected.to contain_php__extension('igbinary') }

        it { is_expected.to contain_package('php7.2-igbinary').with_ensure('absent') }

        it { is_expected.to contain_php__extension('mysqlnd')
          .with_ensure('present')
          .with_versioned_packages(false)
          .with_priority(20)
          .with_config({'mysql.persistent_connections' => false})
        }
      end
      context 'adding config options' do
        let(:params) do
          super().merge({
            'config_by_sapi' => {
              'cli' => {
                'mysql' => { 'connect_timeout' => 2}
              }
            }
          })
        end
        it { is_expected.to compile }

        it { is_expected.to contain_file('/etc/php/7.2/cli/php.ini')
          .with_mode('0444')
          .with_owner('root')
          .with_group('root')
          .with_content(/^mysql.connect_timeout = 2/)
        }
      end
    end
  end
end
