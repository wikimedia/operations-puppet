# concat

#### 目次

1. [概要](#overview)
2. [説明 - モジュールの機能とその有益性](#module-description)
    * [concatを開始する](#beginning-with-concat)
4. [使用方法 - 設定オプションと追加機能](#usage)
5. [参考 - モジュールの機能と動作について](#reference)
    * [削除した機能](#removed-functionality)
6. [制約事項 - OSの互換性など](#limitations)
7. [開発 - モジュール貢献についてのガイド](#development)

<a id="overview"></a>
## 概要

concatモジュールでは、複数の順序付きテキストフラグメントからファイルを構築できます。

<a id="module-description"></a>
## モジュールの概要

concatモジュールでは、他のモジュールから`concat::fragment`リソースを収集し、それを単一の`concat` リソースを通じて整合性のあるファイルに並べることができます。

<a id="beginning-with-concat"></a>
### concatを開始する

concatを開始するには、以下の作成が必要です。

* 最終ファイルのconcat{}リソース。
* 1つ以上のconcat::fragment{}。

最小限の例:

~~~
concat { '/tmp/file':
  ensure => present,
}

concat::fragment { 'tmpfile':
  target  => '/tmp/file',
  content => 'test contents',
  order   => '01'
}
~~~

<a id="usage"></a>
## 使用方法

### ノードの主要モジュールのリストを維持します

いずれかのノードのモジュールをリストするmotdファイルを維持するには、まずファイルをフレームするクラスを作成します。

~~~
class motd {
  $motd = '/etc/motd'

  concat { $motd:
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  concat::fragment{ 'motd_header':
    target  => $motd,
    content => "\nPuppet modules on this server:\n\n",
    order   => '01'
  }

  # let local users add to the motd by creating a file called
  # /etc/motd.local
  concat::fragment{ 'motd_local':
    target => $motd,
    source => '/etc/motd.local',
    order  => '15'
  }
}

# let other modules register themselves in the motd
define motd::register($content="", $order='10') {
  if $content == "" {
    $body = $name
  } else {
    $body = $content
  }

  concat::fragment{ "motd_fragment_$name":
    target  => '/etc/motd',
    order   => $order,
    content => "    -- $body\n"
  }
}
~~~

次に、ノードの各モジュールの宣言に`motd::register{ 'Apache': }`を追加し、motdのモジュールを登録します。

~~~
class apache {
  include apache::install, apache::config, apache::service

  motd::register{ 'Apache': }
}
~~~

これらの2つのステップは、インストールされ、登録されたモジュールのリストを/etc/motdファイルに追加します。このファイルは、登録済みモジュールの`include`行を削除しただけであっても最新の状態を保ちます。システム管理者は、/etc/motd.localに書き込むことでリストにテキストを追加できます。

完成したmotdファイルは、以下のようになります。

~~~
  Puppet modules on this server:

    -- Apache
    -- MySQL

  <contents of /etc/motd.local>
~~~

<a id="reference"></a>
## リファレンス

[REFERENCE.md](https://github.com/puppetlabs/puppetlabs-concat/blob/main/REFERENCE.md)を参照してください。

<a id="removed-functionality"></a>
### 削除した機能

次の機能は、concatモジュールの過去のバージョンには存在していましたが、バージョン2.0.0では削除されています。

`concat::fragment`から削除されたパラメータ:
* `gnu`
* `backup`
* `group`
* `mode`
* `owner`

`concat::setup`クラスも削除されました。

バージョン2.0.0以前のconcatでは、`warn`パラメータを`true`、`false`、'yes'、'no'、'on'、または'off'の文字列値に設定すると、モジュールは文字列を対応するブール値に変換していました。concatバージョン2.0.0以降では、`warn_header`パラメータはこれらの値を他の文字列と同じように扱い、ヘッダメッセージの内容として使用します。これを回避するには、`true`および`false`値を文字列ではなくブール値として渡します。

<a id="limitations"></a>
## 制約事項

このモジュールは[PE対応のすべてのプラットフォーム](https://forge.puppetlabs.com/supported#compat-matrix)上でテスト済みであり、問題は発見されていません。

サポートされているオペレーティングシステムの一覧については、[metadata.json](https://github.com/puppetlabs/puppetlabs-concat/blob/main/metadata.json)を参照してください。

<a id="development"></a>
## 開発

Puppet Forge上のPuppetモジュールはオープンプロジェクトであり、その価値を維持するにはコミュニティからの貢献が欠かせません。Puppetが提供する膨大な数のプラットフォームや、無数のハードウェア、ソフトウェア、デプロイ設定に弊社がアクセスすることは不可能です。

弊社は、できるだけ変更に貢献しやすくして、弊社のモジュールがユーザの環境で機能する状態を維持したいと考えています。弊社では、状況を把握できるよう、貢献者に従っていただくべきいくつかのガイドラインを設けています。

詳細については、[モジュール貢献ガイド](https://docs.puppetlabs.com/forge/contributing.html)を参照してください。

### コントリビュータ

Richard Pijnenburg ([@Richardp82](http://twitter.com/richardp82))

Joshua Hoblitt ([@jhoblitt](http://twitter.com/jhoblitt))

[その他のコントリビュータ](https://github.com/puppetlabs/puppetlabs-concat/graphs/contributors)
