require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'php::fpm::pool' do
  on_supported_os(test_on).each do |_os, facts|
    let(:facts) {facts}
    let(:title) { 'www' }
    let(:pre_condition) {
      [
        'class { "::php": sapis => ["fpm"]}',
        'class { "::php::fpm": }'
      ]
    }
    context 'with default parameters' do
      it { is_expected.to compile.with_all_deps }
      matcher = 'listen = /run/php/fpm-www.sock'
      it { is_expected.to contain_file('/etc/php/7.0/fpm/pool.d/www.conf')
                            .with_content(/#{matcher}/)
                            .with_owner('root')
                            .that_notifies('Service[php7.0-fpm]')
      }
    end
    context 'when provided a port' do
      let(:params) { { 'port' => 9000 } }
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/etc/php/7.0/fpm/pool.d/www.conf')
                            .with_content(/listen = 127.0.0.1:9000\n/)
      }
    end
  end
end
