# Herdr Title Sync

Herdr 0.9.0+ の公式プラグイン機構を使い、エージェントが設定した
`terminal_title_stripped` を表示名へ同期する自作プラグインです。

- Agent: タイトルをHerdrの制約に合わせた小文字slugのAgent名へ同期
- Tab: Agentが1つだけのTabに限り、同じタイトルへ同期
- 複数AgentのTab: Tab名は変更しない
- Space / workspace: `project` metadataが明示された場合だけ変更
- 追加LLM、端末本文の収集、常駐監視: なし

homebox/Linuxで使うための設定です。dotfilesのmacOSセットアップからは自動登録しません。

## Space名の設定

virtual monorepoのルートではcwdだけでは実際の作業リポジトリを判定できないため、
会話内容から推測しません。Workspaceごとにプロジェクトを明示してください。

```sh
herdr workspace report-metadata w18 \
  --source local.title-sync \
  --token project=home-server
```

以後、代表Agentのタイトルに合わせて次のように更新されます。

```text
home-server - Automate Panel Renaming - GitHub Copilot
```

`project` metadataがないWorkspaceは変更しません。複数Agentの場合は、focused、
working、その他の順で代表Agentを選びます。Workspace名を手動変更すると、その後は
自動更新を停止します。

## homeboxでの登録

dotfilesを`~/dotfiles`に配置した状態で、Herdrサーバー上で実行します。

```sh
herdr plugin link ~/dotfiles/ubuntu/herdr/title-sync
herdr plugin enable local.title-sync
herdr plugin action invoke local.title-sync.sync-all
```

既存のリンクを更新した場合、再リンクは不要です。Herdrが次のイベントから
作業ツリーのスクリプトを実行します。

停止・撤去:

```sh
herdr plugin disable local.title-sync
herdr plugin unlink local.title-sync
```

無効化・unlinkは既存のラベルを自動的に元へ戻しません。

## 手動リネーム

Tabは、既定の番号ラベルまたはこのプラグインが直前に設定したラベルから
手動変更されたことを検出すると、それ以降は自動更新しません。
状態はHerdrのプラグイン状態ディレクトリに保存されます。

AgentについてはHerdr 0.9.0の取得APIが現在のAgentラベルを返さないため、
Tabと同じ完全な手動リネーム検出はできません。手動名を優先したい場合は
プラグインを無効化してください。将来Herdr APIがAgentラベルを返すようになれば
同じ保護を追加できます。

Agent名はHerdr APIの制約により、タイトルを小文字の英数字・`-`・`_`へ
正規化した識別子になります。自然言語の元タイトルはTab側に保持されます。

## 制約

Herdrにタイトル変更専用イベントがないため、状態変化時に同期します。
タイトルだけが変わった場合は、次のAgentイベントか `sync-all` まで反映されません。
リネーム処理は同一プラグイン内でロックし、CLI呼び出しには10秒のタイムアウトを
設定しています。
