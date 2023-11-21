require_relative "../../../../rake_modules/spec_helper"

describe "rsync::server::module", type: :define do
  let :title do
    "foo"
  end

  let :pre_condition do
    'class { "rsync::server": }'
  end

  let :params do
    { path: "/some/path" }
  end

  describe "when using default class parameters" do
    it do
      is_expected.to contain_concat__fragment("/etc/rsyncd.conf-foo")
        .with_content(/^\[ foo \]$/)
        .with_content(%r{^path\s*=\s*/some/path$})
        .with_content(/^read only\s*=\s*yes$/)
        .with_content(/^write only\s*=\s*no$/)
        .with_content(/^list\s*=\s*yes$/)
        .with_content(/^uid\s*=\s*0$/)
        .with_content(/^gid\s*=\s*0$/)
        .with_content(/^use chroot\s*=\s*yes$/)
        .with_content(/^max connections\s*=\s*0$/)
    end

    it do
      is_expected.not_to contain_concat__fragment("/etc/rsyncd.conf-foo")
        .with_content(/^incoming chmod\s*=/)
        .with_content(/^outgoing chmod\s*=/)
        .with_content(/^lock file\s*=.*$/)
        .with_content(/^secrets file\s*=.*$/)
        .with_content(/^auth users\s*=.*$/)
        .with_content(/^hosts allow\s*=.*$/)
        .with_content(/^hosts deny\s*=.*$/)
    end
  end

  describe "when overriding max connections" do
    let :params do
      super().merge({ max_connections: 1 })
    end
    it do
      is_expected.to contain_concat__fragment(
        "/etc/rsyncd.conf-foo"
      ).with_content(/^max connections\s*=\s*1$/).with_content(
        %r{^lock file\s*=\s*/var/run/rsyncd\.lock$}
      )
    end
  end

  {
    comment: "super module !",
    read_only: "no",
    write_only: "yes",
    list: "no",
    uid: "4682",
    gid: "4682",
    incoming_chmod: "0777",
    outgoing_chmod: "0777",
    secrets_file: "/path/to/secrets",
    hosts_allow: %w[localhost 169.254.42.51].join(" "),
    hosts_deny: %w[some-host.example.com 10.0.0.128].join(" ")
  }.each do |k, v|
    describe "when overriding #{k}" do
      let :params do
        super().merge({ k => v })
      end
      it do
        is_expected.to contain_concat__fragment(
          "/etc/rsyncd.conf-foo"
        ).with_content(/^#{k.to_s.gsub("_", " ")}\s*=\s*#{v}$/)
      end
    end
  end

  describe "when overriding auth_users" do
    let :params do
      super().merge({ auth_users: %w[me you them] })
    end
    it do
      is_expected.to contain_concat__fragment(
        "/etc/rsyncd.conf-foo"
      ).with_content(/^auth users\s*=\s*me, you, them$/)
    end
  end
  describe "when overriding chroot" do
    let :params do
      super().merge(chroot: false)
    end
    it do
      is_expected.to contain_concat__fragment(
        "/etc/rsyncd.conf-foo"
      ).with_content(/^use chroot\s*=\s*no$/)
    end
  end
end
