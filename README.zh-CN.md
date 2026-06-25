# 🦉 Cluolingo

> **Claude × Duolingo** —— 让 AI 干活的同时,顺便练语言。一个**不阻塞**的 [Claude Code](https://claude.com/claude-code) 陪练伙伴。

[English](README.md) · **简体中文** · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português](README.pt.md)

一个刻意的设计原则:**它永远不挡你。**

Cluolingo 把你真正的任务丢给**后台 agent** 去跑,然后在聊天里口语地塞一道语言小测 —— *「小测一下,趁这个在跑…」*。工作一完成,结果立刻给你 —— 答没答都一样。一个柔性伙伴,绝不是 gate。

多语言:默认练英文,或 `cluo lang Japanese` / `cluo lang Spanish`,想练哪种都行。

## 工作原理

一个 `UserPromptSubmit` hook 会在每条 prompt 注入行为指令。遇到实质任务时,Claude 被指示要:

1. **改写**你的需求成地道的**{目标语言}** + 2–4 条短语笔记(「_语言_ version」区块)。
2. **派发**实际工作给后台 agent,让它一边跑、你一边聊。
3. **塞一道快速小测** —— 从改写/笔记里抽一道填空或选择。
4. **永不等待。** 后台任务一回报,结果就呈现,不管你有没有答题。小测是选配练习,不是关卡。

你答题后,分数会通过 `cluo` CLI 更新。

```
你  ▸ 帮我把这个列表加上分页
AI  ▸ English version
        Rewrite: "Add pagination to this list for me."
        Phrasing notes: 分页 → pagination(不是 "paging")
      Quick quiz: 把列表切成一页页的动作,英文叫 p_________?
      🔧 已把分页的工作丢到后台跑。
      (用 `! cluo answer pagination` 回答,或直接打字 —— 代码好了就贴上)
```

## 附带好处:改写本身就是一次「理解校验」

你随手丢一个粗略的 prompt;动手之前,Cluolingo 会用你练习的语言回敬一份润色过的改写版。只要你读得懂,这份改写立刻告诉你 **AI 到底有没有理解你的需求** —— 让你在它跑去做错事之前就抓到误解。所以这份改写一鱼两吃:既练语言,**又**是一面照出 AI 理解程度的镜子。

## 怎么答题最不扰主流程

三种方式 —— 都会给「对/错 + 正解」,差别在**解说**和**会不会计分**:

| 方式 | 解说 | 计分 |
|---|---|---|
| `! cluo answer pagination` | 出题时就存好的固定一句 —— 本地、零 token、不进对话 | ✅ |
| 在聊天回 `pagination` | Claude 即时看你的答案客制批改(会点出你哪里错);算一点点 token | ✅ |
| 内建 `/btw pagination` | 跟聊天回覆一样即时,但跑在唯读 fork | ❌ |

`cluo` 是完整 CLI —— 用 `!` 前缀跑(例 `! cluo stats`)。

## 安装

### 作为 Claude Code 插件(推荐)

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### 全局(手动)安装

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

这会把 `cluo` CLI 链接到你的 PATH,并把 hook 写进 `~/.claude/settings.json`。随时可重跑;卸载用 `./install.sh --uninstall`。

> 需要 [`jq`](https://jqlang.github.io/jq/)(`brew install jq`)。

## CLI 命令(`cluo`)

在 Claude Code 里用零 token 的 `!` 前缀执行,例如 `! cluo stats`。

| 命令 | 作用 |
|---|---|
| `cluo answer <答案>` | 回答**最近一题**待答题目(当场计分) |
| `cluo answer @N [answer]` | 按编号答**指定**一题（从 1 起，即 `pending`/偷看列出的 `@N`）—— 可先答旧题 |
| `cluo answer --all [@N] [answer]` | 本次调用：覆盖**全部** session 的积压题目（清掉已退出 session 留下的孤立题） |
| `cluo answer --mine [@N] [answer]` | 本次调用：只限**当前** session（覆盖 `scope=all`） |
| `cluo pending [--all]` | 列出你的待答题目，每题标 `@N` 编号。`--all` = 列出每个 session 的，各标 session id |
| `cluo stats` | 显示记分板(语言、正确率、连胜、学过的词) |
| `cluo lang <语言>` | 设置目标练习语言(例 `cluo lang Japanese`) |
| `cluo native <语言>` | 设置你的母语(默认 Chinese) |
| `cluo on` / `cluo off` | 启用 / 停用陪练 |
| `cluo preset chill\|normal\|hardcore` | `chill` = 每任务 20% 概率;`normal`/`hardcore` = 每任务都考 |
| `cluo set mode every\|freq\|chance` | 触发模式 |
| `cluo set freq <N>` | `freq` 模式下每 N 条 prompt 考一次 |
| `cluo set chance <0-100>` | `chance` 模式下每条 prompt 的触发概率 % |
| `cluo set scope all\|session` | `cluo answer` 的默认范围。`all` = 覆盖全部 session(无需每次带 `--all`)；`session` = 仅当前 session(默认) |
| `cluo reset` | 重置记分板(保留设置) |
| `cluo ask <答案> [讲解] [题目]` · `cluo grade correct\|wrong` · `cluo word <词语>` | 由 Claude 出题/批改时调用(pending 是队列,多题不互盖) |

## 语言

想练什么语言都行 —— 目标语言只是喂给 Claude 的一个标签:

```
cluo lang English      # 默认
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # 只要 Claude 看得懂
cluo native Chinese    # 短语笔记用的母语
```

## 触发模式

- **every**(默认)—— 每个实质任务都来一道快速小测。
- **freq** —— 每 `N` 条 prompt 考一次。
- **chance** —— 每条 prompt 以 `chance`% 概率触发(轮盘)。

## 逃生口与 fail-open

- `!` 开头的 prompt(shell 命令)永远不会被碰。
- 若缺 `jq`、陪练被停用、或任何出错,hook 一律 **fail open** —— 你的 prompt 一定送得出去。

## 状态

记分板与设置存在 `~/.claude/cluolingo/state.json`(或 `$CLAUDE_CONFIG_DIR/cluolingo/`)。

## 许可

MIT
