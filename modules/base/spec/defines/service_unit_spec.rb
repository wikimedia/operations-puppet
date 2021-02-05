require_relative '../../../../rake_modules/spec_helper'

describe 'base::service_unit' do
  let(:title) { 'nginx' }
  let(:params) { {ensure: 'present', systemd: 'test'} }

  context 'with systemd as init' do
    context 'with a systemd unit file' do
      it { is_expected.to contain_service('nginx').only_with(ensure: 'running', enable: true) }
      it { is_expected.to contain_file('/lib/systemd/system/nginx.service').with_content('test') }
      it do
        is_expected.to contain_exec('systemd reload for nginx')
          .that_comes_before('Service[nginx]')
          .that_subscribes_to('File[/lib/systemd/system/nginx.service]')
      end
    end
  end

  context 'with refresh false' do
    let(:params) { super().merge(refresh: false) }

    it 'should not refresh service' do
      is_expected.to contain_file('/lib/systemd/system/nginx.service')
        .that_comes_before('Service[nginx]')
        .without_notify
    end
  end

  context 'with mask true' do
    let(:params) { super().merge(mask: true) }

    it 'should not refresh service' do
      is_expected.to contain_file('/etc/systemd/system/nginx.service')
        .with_ensure('link')
        .with_target('/dev/null')
    end
  end

  context 'with declare_service false' do
    let(:params) { super().merge(declare_service: false) }

    it { is_expected.not_to contain_service('nginx') }
  end

  context 'with declare_service false' do
    let(:params) { super().merge(service_params: {hasstatus: false}) }

    it do
      is_expected.to contain_service('nginx').only_with(
        ensure: 'running',
        enable: true,
        hasstatus: false
      )
    end
  end
end
