# Dependabot Alerts API 実戦メモ

## dismissed_reason の有効値

| 値 | 説明 |
|---|---|
| `fix_started` | 修正作業を開始済み |
| `inaccurate` | アラートが不正確 |
| `no_bandwidth` | 対応リソースなし |
| `not_used` | 該当コードパスを使用していない |
| `tolerable_risk` | 許容可能なリスク |

**`not_impacted` は無効値。HTTP 422エラーを返す。**

## dismiss理由テンプレート

- 推移的依存: `Transitive dependency via {parent_package}. Awaiting upstream update.`
- Windows限定: `Dev dependency only. Vulnerability is Windows-specific, not applicable to our macOS/Linux CI.`
- devDependency低リスク: `Dev dependency only. Low risk in development context.`

## 実戦で判明した落とし穴

### Node.js (pnpm)

1. **`pnpm update` が効かないケース**: package.jsonで固定バージョン指定（`"9.1.17"`等、`^`なし）の場合、`pnpm update`は「Already up to date」を返す。`pnpm add`で明示的にバージョン指定が必要
2. **`@latest` のメジャーバージョン爆死**: `pnpm add pkg@latest`はメジャーバージョンを引く。ピアデペンデンシーが崩壊する。パッチバージョンを明示指定すること
3. **推移的依存は`pnpm update`で更新不可**: `pnpm update <transitive-dep>`は効果なし。`pnpm.overrides`は互換性リスクがあるため原則使わない
4. **dismiss後もアラートが残る場合**: lockfileの更新をpushすると、直接依存の更新分は自動クローズされる。push前のdismissとpush後の自動クローズは別の仕組み

### Go

1. **推移的依存の `go get`**: `go get <indirect-module>@version` は go.mod に直接追加されてしまう。推移的依存の更新は上流モジュールの更新（`go get <direct-module>@version`）で対応するのが正道
2. **`go mod tidy` の副作用**: 未使用の直接依存も削除されるため、意図しない変更が入る可能性あり。差分を確認すること
3. **`// indirect` の判定**: `go.mod` の `require` ブロック内で行末に `// indirect` コメントがあるものが推移的依存。ないものが直接依存
