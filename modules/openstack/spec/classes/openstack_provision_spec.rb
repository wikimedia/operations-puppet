require 'spec_helper'

describe 'openstack::provision' do

  let :facts do
    {
    :osfamily => 'Debian'
    }
  end

  describe 'creates a glance image and an alt' do
    let :params do
      {
        :image_name    => 'cirros',
        :image_source  => 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img',
        :image_name_alt    => 'cirros2',
      }
    end

    it { should contain_glance_image(params[:image_name_alt]).with(
      :ensure           => 'present',
      :is_public        => 'yes',
      :container_format => 'bare',
      :disk_format      => 'qcow2',
      :source           => params[:image_source]
      )
    }

    it { should contain_glance_image(params[:image_name]).with(
      :ensure           => 'present',
      :is_public        => 'yes',
      :container_format => 'bare',
      :disk_format      => 'qcow2',
      :source           => params[:image_source]
      )
    }
  end

  describe 'creates a glance image' do
    let :params do
      {
        :image_name    => 'cirros',
        :image_source  => 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img',
      }
    end

    it { should contain_glance_image(params[:image_name]).with(
      :ensure           => 'present',
      :is_public        => 'yes',
      :container_format => 'bare',
      :disk_format      => 'qcow2',
      :source           => params[:image_source]
      )
    }
  end

  describe 'should be possible to override resize_available' do
    let :params do
      {
        :configure_tempest         => true,
        :resize_available          => true,
        :change_password_available => true,
        :tempest_repo_revision     => 'stable/grizzly'
      }
    end

    it { should contain_class('tempest').with(
      :resize_available          => true,
      :change_password_available => true,
      :tempest_repo_revision     => 'stable/grizzly'
    ) }

    it 'should configure neutron networks' do
      should contain_neutron_network('public').with(
        'ensure'          => 'present',
        'router_external' => true,
        'tenant_name'     => 'admin'
      )
      should contain_neutron_network('private').with(
        'ensure'          => 'present',
        'tenant_name'     => 'demo'
      )
    end

  end

  describe 'should be possible to provision with neutron disabled' do
    let :params do
      {
        :configure_tempest     => true,
        :neutron_available     => false,
        :tempest_repo_revision => 'stable/grizzly'
      }
    end

    it { should contain_class('tempest').with(
      :tempest_repo_revision     => 'stable/grizzly'
    ) }
  end

end
