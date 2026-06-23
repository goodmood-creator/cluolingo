# 🦉 Cluolingo

> **Claude × Duolingo** —— AI が働いている間に、ついでに語学を練習。[Claude Code](https://claude.com/claude-code) 向けの**ブロックしない**学習コンパニオン。

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · **日本語** · [한국어](README.ko.md) · [Español](README.es.md) · [Português](README.pt.md)

ひとつの明確な設計方針：**あなたを止めません。**

Cluolingo は実際のタスクを**バックグラウンドのエージェント**に投げ、その間チャットにさりげなく語学の問題を差し込みます —— *「btw、動いてる間にひとつだけ…」*。作業が終わった瞬間、答えても答えなくても結果が返ります。柔らかいコンパニオンであって、ゲートではありません。

多言語対応：デフォルトは英語、または `cluo lang Japanese` / `cluo lang Spanish` など何でも。

## 仕組み

`UserPromptSubmit` フックが毎回のプロンプトに振る舞いの指示を注入します。実質的なタスクの場合、Claude は次のように指示されます：

1. リクエストを洗練された **{ターゲット言語}** に**書き換え** + 2〜4 個の言い回しメモ（「_言語_ version」ブロック）。
2. 実際の作業をバックグラウンドエージェントに**ディスパッチ**し、会話と並行して実行。
3. **「btw」を差し込む** —— 書き換えから穴埋めか選択式の問題を 1 問。
4. **決して待たない。** バックグラウンドのタスクが返ってきた瞬間、問題に答えたかどうかに関係なく結果を提示。問題は任意の練習であり、ゲートではありません。

回答するとスコアボードが `cluo` CLI 経由で更新されます。

```
あなた ▸ 幫我把這個列表加上分頁
AI     ▸ English version
           Rewrite: "Add pagination to this list for me."
           Notes: 分頁 → pagination（「paging」ではない）…
         🔧 ページング処理をバックグラウンドで開始しました。
         btw、動いてる間にひとつ：
           リストをページに分ける動作は英語で p_________？
         (`/btw pagination` で回答、または `! cluo answer pagination`、もしくは普通に返信 —— コードは準備でき次第貼ります)
```

## メインの流れを邪魔しない回答方法

3 通り、その時の気分で選べます：

- **`/btw pagination`（手軽）：** スラッシュコマンド。Claude が採点し、連勝を更新し、一言の解説を添えます。`/` メニューから見つけられます。会話を経由するため、少しだけコストがかかります。
- **`! cluo answer pagination`（ゼロ干渉）：** `!` シェル接頭辞はローカルで実行され、トークンを消費せず会話にも入らないため、メインのタスクを汚しません。CLI が即座に採点します。
- **チャットで `pagination` と返信：** Claude が一言の解説つきで温かく採点します。少しだけコンテキストを使いますが、学びは深いです。

`/btw` は回答用のスラッシュコマンドのショートカット、`cluo` は完全な CLI —— `!` 接頭辞で実行します（例：`! cluo stats`）。

## インストール

### Claude Code プラグインとして（推奨）

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### グローバル（手動）インストール

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

`cluo` CLI を PATH にリンクし、フックを `~/.claude/settings.json` に組み込みます。いつでも再実行可能。アンインストールは `./install.sh --uninstall`。

> [`jq`](https://jqlang.github.io/jq/) が必要です（`brew install jq`）。

## CLI コマンド（`cluo`）

Claude Code 内でトークン消費ゼロの `!` 接頭辞で実行します（例：`! cluo stats`）。（問題への回答は、上の `/btw` スラッシュコマンドの方がたいてい簡単です。）

| コマンド | 効果 |
|---|---|
| `cluo answer <答え>` | **最新の**保留中の問題に回答（`/btw <答え>` スラッシュコマンドも同じ動作） |
| `cluo pending` | 未回答の問題を一覧表示 |
| `cluo stats` | スコアボード表示（言語・正解率・連勝・覚えた単語） |
| `cluo lang <言語>` | 練習するターゲット言語を設定（例 `cluo lang Japanese`） |
| `cluo native <言語>` | 母語を設定（デフォルト Chinese） |
| `cluo on` / `cluo off` | コンパニオンを有効 / 無効 |
| `cluo preset chill\|normal\|hardcore` | `chill` = タスクごと 20%；`normal`/`hardcore` = 毎タスク |
| `cluo set mode every\|freq\|chance` | トリガーモード |
| `cluo set freq <N>` | `freq` モードで N プロンプトごとに出題 |
| `cluo set chance <0-100>` | `chance` モードでプロンプトごとの確率 % |
| `cluo reset` | スコアボードをリセット（設定は保持） |
| `cluo ask <答え> [解説] [問題]` · `cluo grade correct\|wrong` · `cluo word <語句>` | Claude が出題・採点時に呼び出す（pending はキューで多問が衝突しない） |

## 言語

どんな言語でも練習可能 —— ターゲットは Claude に渡すラベルにすぎません：

```
cluo lang English      # デフォルト
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # Claude が理解できるもの何でも
cluo native Chinese    # 言い回しメモ用の母語
```

## トリガーモード

- **every**（デフォルト）—— 実質的なタスクごとに「btw」。
- **freq** —— `N` プロンプトごとに出題。
- **chance** —— プロンプトごとに `chance`% の確率で出題（ルーレット）。

## エスケープと fail-open

- `!` で始まるプロンプト（シェルコマンド）は一切触れません。
- `jq` がない、コンパニオンが無効、または何かエラーが起きた場合、フックは **fail open** —— プロンプトは必ず通ります。

## 状態

スコアボードと設定は `~/.claude/cluolingo/state.json`（または `$CLAUDE_CONFIG_DIR/cluolingo/`）に保存されます。

## ライセンス

MIT
