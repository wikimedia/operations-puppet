require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'php' do
  on_supported_os(test_on).each do |_os, facts|
    let(:facts) { facts }
    context 'default parameters' do
      it { is_expected.to compile }

      it { is_expected.to contain_class('php::default_extensions') }
      it { is_expected.to contain_package('php7.0-cli') }
      it { is_expected.to contain_file('/etc/php/7.0/cli/conf.d')
                            .with_mode('0755').with_ensure('directory')
                            .with_owner('root').with_group('root')
      }
      it { is_expected.to contain_file('/etc/php/7.0/cli/php.ini')
                            .with_mode('0444')
                            .with_owner('root')
                            .with_group('root')
                            .with_content(/^mysql.connect_timeout = 1/)
      }
    end
    context 'non-default PHP version' do
      let(:params) {{ 'version' => '7.2' }}
      it { is_expected.to compile }
      it { is_expected.to contain_package('php7.2-cli') }
      it { is_expected.to contain_file('/etc/php/7.2/cli/conf.d')
                            .with_mode('0755').with_ensure('directory')
                            .with_owner('root').with_group('root')
                            .with_recurse(true)
                            .with_purge(true)
      }
      it { is_expected.to contain_file('/etc/php/7.2/cli/php.ini')
                            .with_mode('0444')
                            .with_owner('root')
                            .with_group('root')
                            .with_content(/^mysql.connect_timeout = 1/)
      }
    end

    context 'more than one sapi' do
      let(:params) do
        {
          'sapis' => ['cli', 'fpm']
        }
      end
      it { is_expected.to compile }

      it { is_expected.to contain_class('php::default_extensions') }
      it { is_expected.to contain_package('php7.0-cli') }
      it { is_expected.to contain_package('php7.0-fpm') }
      it { is_expected.to contain_file('/etc/php/7.0/fpm/conf.d')
                            .with_mode('0755').with_ensure('directory')
                            .with_owner('root').with_group('root')
      }
      it { is_expected.to contain_file('/etc/php/7.0/fpm/php.ini')
                            .with_mode('0444')
                            .with_owner('root')
                            .with_group('root')
                            .with_content(/^mysql.connect_timeout = 1/)
      }
    end
    context 'configuring extensions' do
      let(:params) do
        {
          'extensions' => {
            'igbinary' => {'package_name' => 'php7.0-igbinary', 'ensure' => 'absent'},
            'mysqlnd'  => {'config' => {'mysql.persistent_connections' => false}}
          }
        }
      end
      it { is_expected.to compile }

      it { is_expected.to contain_php__extension('igbinary')
                            .with_package_name('php7.0-igbinary')
                            .with_ensure('absent')
      }

      it { is_expected.to contain_php__extension('mysqlnd')
                            .with_ensure('present')
                            .with_package_name('php-mysqlnd')
                            .with_priority(20)
                            .with_config({'mysql.persistent_connections' => false})
      }
    end
    context 'adding config options' do
      let(:params) do
        {
          'config_by_sapi' => {
            'cli' => {
              'mysql' => { 'connect_timeout' => 2}
            }
          }
        }
      end
      it { is_expected.to compile }

      it { is_expected.to contain_file('/etc/php/7.0/cli/php.ini')
                            .with_mode('0444')
                            .with_owner('root')
                            .with_group('root')
                            .with_content(/^mysql.connect_timeout = 2/)
      }
    end
  end
end
