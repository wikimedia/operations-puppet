require_relative "../../../../rake_modules/spec_helper"

describe "rsync::server", type: :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe "when using default params" do
        it { is_expected.to contain_service("rsync") }
        it do
          is_expected.to contain_concat__fragment(
            "/etc/rsyncd.conf-header"
          ).with_content(/^use chroot\s*=\s*yes$/).with_content(
            /^address\s*=\s*0.0.0.0$/
          )
        end
      end

      describe "when overriding use_chroot" do
        let :params do
          { use_chroot: "no" }
        end

        it do
          is_expected.to contain_concat__fragment(
            "/etc/rsyncd.conf-header"
          ).with_content(/^use chroot\s*=\s*no$/)
        end
      end

      describe "when overriding address" do
        let :params do
          { address: "10.0.0.42" }
        end

        it do
          is_expected.to contain_concat__fragment(
            "/etc/rsyncd.conf-header"
          ).with_content(/^address\s*=\s*10.0.0.42$/)
        end
      end

      describe "when passing configuration" do
        let :params do
          { rsyncd_conf: { "forward lookup" => "no", "use chroot" => "yes" } }
        end

        it do
          is_expected.to contain_concat__fragment(
            "/etc/rsyncd.conf-header"
          ).with_content(/^use chroot = yes$/).with_content(
            /^forward lookup = no$/
          )
        end
      end
    end
  end
end
