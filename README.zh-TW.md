# 🦉 Cluolingo

> **Claude × Duolingo** —— 讓 AI 幹活的同時,順便練語言。一個**不阻塞**的 [Claude Code](https://claude.com/claude-code) 陪練夥伴。

[English](README.md) · [简体中文](README.zh-CN.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português](README.pt.md)

一個刻意的設計原則:**它永遠不擋你。**

Cluolingo 把你真正的任務丟給**背景 agent** 去跑,然後在聊天裡口語地塞一題語言小考 —— *「小考一下,趁這個在跑…」*。工作一完成,結果立刻給你 —— 答沒答都一樣。一個柔性夥伴,絕不是 gate。

多語言:預設練英文,或 `cluo lang Japanese` / `cluo lang Spanish`,想練哪種都行。

## 運作原理

一個 `UserPromptSubmit` hook 會在每則 prompt 注入行為指令。遇到實質任務時,Claude 被指示要:

1. **改寫**你的需求成道地的**{目標語言}** + 2–4 條片語筆記(「_語言_ version」區塊)。
2. **派發**實際工作給背景 agent,讓它一邊跑、你一邊聊。
3. **塞一題快速小考** —— 從改寫/筆記裡抽一題填空或選擇。
4. **永不等待。** 背景任務一回報,結果就呈現,不管你有沒有答題。小考是選配練習,不是關卡。

你答題後,分數會透過 `cluo` CLI 更新。

```
你  ▸ 幫我把這個列表加上分頁
AI  ▸ English version
        Rewrite: "Add pagination to this list for me."
        Phrasing notes: 分頁 → pagination(不是 "paging")
      Quick quiz: 把列表切成一頁頁的動作,英文叫 p_________?
      🔧 已把分頁的工作丟到背景跑。
      (用 `! cluo answer pagination` 回答,或直接打字 —— 程式碼好了就貼上)
```

## 附帶好處:改寫本身就是一次「理解校驗」

你隨手丟一個粗略的 prompt;動手之前,Cluolingo 會用你練習的語言回敬一份潤色過的改寫版。只要你讀得懂,這份改寫立刻告訴你 **AI 到底有沒有理解你的需求** —— 讓你在它跑去做錯事之前就抓到誤解。所以這份改寫一魚兩吃:既練語言,**又**是一面照出 AI 理解程度的鏡子。

## 怎麼答題最不擾主流程

三種方式 —— 都會給「對/錯 + 正解」,差別在**解說**和**會不會計分**:

| 方式 | 解說 | 計分 |
|---|---|---|
| `! cluo answer pagination` | 出題時就存好的固定一句 —— 本地、零 token、不進對話 | ✅ |
| 在聊天回 `pagination` | Claude 即時看你的答案客製批改(會點出你哪裡錯);算一點點 token | ✅ |
| 內建 `/btw pagination` | 跟聊天回覆一樣即時,但跑在唯讀 fork | ❌ |

`cluo` 是完整 CLI —— 用 `!` 前綴跑(例 `! cluo stats`)。

## 安裝

### 作為 Claude Code plugin(推薦)

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### 全域(手動)安裝

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

這會把 `cluo` CLI 連到你的 PATH,並把 hook 寫進 `~/.claude/settings.json`。隨時可重跑;移除用 `./install.sh --uninstall`。

> 需要 [`jq`](https://jqlang.github.io/jq/)(`brew install jq`)。

## CLI 指令(`cluo`)

在 Claude Code 裡用零 token 的 `!` 前綴執行,例如 `! cluo stats`。

| 指令 | 作用 |
|---|---|
| `cluo answer [答案]` | 回答你**最近一題**待答題目(當場計分)。**不帶答案 = 偷看**你這個 session 有哪些待答 |
| `cluo answer @N [answer]` | 按編號回答**指定**的一題(從 1 起,即 `pending`/偷看所示的 `@N`)—— 可先答較早的題 |
| `cluo answer --all [@N] [answer]` | 本次呼叫:覆蓋**所有** session 的積壓題目(清掉已結束 session 留下的孤立題) |
| `cluo answer --mine [@N] [answer]` | 本次呼叫:只限**此** session(覆蓋 `scope=all`) |
| `cluo pending [--all]` | 列出你的待答題目,每題標 `@N` 編號。`--all` = 列出每個 session 的,各標 session id |
| `cluo pending clear [--all]` | 清掉你這個 session 的待答題(+無主舊題)。`--all` = 全 session 清空 |
| `cluo stats` | 顯示計分板(語言、正確率、連勝、學過的字) |
| `cluo lang <語言>` | 設定目標練習語言(例 `cluo lang Japanese`) |
| `cluo native <語言>` | 設定你的母語(預設 Chinese) |
| `cluo on` / `cluo off` | 啟用 / 停用陪練 |
| `cluo preset chill\|normal\|hardcore` | `chill` = 每任務 20% 機率;`normal`/`hardcore` = 每任務都考 |
| `cluo set mode every\|freq\|chance` | 觸發模式 |
| `cluo set freq <N>` | `freq` 模式下每 N 則 prompt 考一次 |
| `cluo set chance <0-100>` | `chance` 模式下每則 prompt 的觸發機率 % |
| `cluo set scope all\|session` | `cluo answer` 的預設範圍。`all` = 覆蓋所有 session(無需帶 `--all`)；`session` = 僅此 session(預設) |
| `cluo reset` | 重置計分板(保留設定) |
| `cluo ask <答案> [解說] [題目]` · `cluo grade correct\|wrong` · `cluo word <字詞>` | 由 Claude 出題/批改時呼叫(pending 是佇列,多題不互蓋) |

## 語言

想練什麼語言都行 —— 目標語言只是餵給 Claude 的一個標籤:

```
cluo lang English      # 預設
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # 只要 Claude 看得懂
cluo native Chinese    # 片語筆記用的母語
```

## 觸發模式

- **every**(預設)—— 每個實質任務都來一題快速小考。
- **freq** —— 每 `N` 則 prompt 考一次。
- **chance** —— 每則 prompt 以 `chance`% 機率觸發(輪盤)。

## 逃生口與 fail-open

- `!` 開頭的 prompt(shell 指令)永遠不會被碰。
- 若缺 `jq`、陪練被停用、或任何出錯,hook 一律 **fail open** —— 你的 prompt 一定送得出去。

## 狀態

計分板與設定存在 `~/.claude/cluolingo/state.json`(或 `$CLAUDE_CONFIG_DIR/cluolingo/`)。

## 授權

MIT
