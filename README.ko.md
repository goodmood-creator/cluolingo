# 🦉 Cluolingo

> **Claude × Duolingo** —— AI가 일하는 동안 겸사겸사 외국어를 연습하세요. [Claude Code](https://claude.com/claude-code)를 위한 **차단하지 않는** 학습 동반자.

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · **한국어** · [Español](README.es.md) · [Português](README.pt.md)

[workout-gate](https://github.com/BotchetDig/workout-gate)에서 영감을 받았지만, 한 가지를 의도적으로 뒤집었습니다: **당신을 멈추지 않습니다.**

- **workout-gate**는 웹캠 앞에서 팔굽혀펴기를 끝낼 때까지 프롬프트를 얼립니다. 단단한 게이트죠.
- **Cluolingo**는 실제 작업을 **백그라운드 에이전트**에 넘기고, 그동안 채팅에 슬쩍 외국어 문제를 끼워 넣습니다 —— *"btw, 돌아가는 동안 하나만…"*. 작업이 끝나는 순간, 답을 했든 안 했든 결과가 돌아옵니다. 게이트가 아니라 부드러운 동반자입니다.

다국어 지원: 기본은 영어, 또는 `cluo lang Japanese` / `cluo lang Spanish` 등 무엇이든.

## 작동 방식

`UserPromptSubmit` 훅이 매 프롬프트마다 동작 지침을 주입합니다. 실질적인 작업일 때 Claude는 다음과 같이 지시받습니다:

1. 요청을 자연스러운 **{대상 언어}**로 **다시 쓰기** + 2~4개의 표현 노트(「_언어_ version」블록).
2. 실제 작업을 백그라운드 에이전트에 **디스패치**하여 대화와 동시에 실행.
3. **"btw" 한마디 끼워 넣기** —— 다시 쓴 문장에서 빈칸 채우기 또는 객관식 문제 하나.
4. **절대 기다리지 않기.** 백그라운드 작업이 돌아오는 순간, 문제에 답했는지와 무관하게 결과를 제시. 문제는 선택적 연습이지 관문이 아닙니다.

답하면 점수판이 `cluo` CLI를 통해 갱신됩니다.

```
당신 ▸ 幫我把這個列表加上分頁
AI   ▸ English version
         Rewrite: "Add pagination to this list for me."
         Notes: 分頁 → pagination ("paging"이 아님)…
       🔧 페이지네이션 작업을 백그라운드에서 시작했습니다.
       btw, 돌아가는 동안 하나:
         리스트를 페이지로 나누는 동작을 영어로 p_________?
       (`! btw answer pagination`으로 답하거나, 그냥 답장 —— 코드는 준비되면 붙여드립니다)
```

## 메인 흐름을 방해하지 않고 답하기

두 가지 방법, 그때그때 기분대로:

- **아웃오브밴드(권장, 제로 간섭):** `! btw answer pagination`. `!` 셸 접두사는 토큰을 소비하지 않고 대화에도 들어가지 않으므로 메인 작업을 오염시키지 않습니다. CLI가 즉시 채점하고 연승을 갱신합니다.
- **채팅 안에서(설명이 필요할 때):** 그냥 `pagination`이라고 답장하세요. Claude가 한 줄 설명과 함께 따뜻하게 채점합니다. 컨텍스트를 조금 더 쓰지만 더 많이 배웁니다.

`btw`와 `cluo`는 **같은 명령어** —— 읽기 편한 쪽을 쓰세요(`! btw answer …`, `! cluo stats`).

## 설치

### Claude Code 플러그인으로(권장)

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### 전역(수동) 설치

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

`cluo` + `btw` CLI를 PATH에 링크하고, 훅을 `~/.claude/settings.json`에 연결합니다. 언제든 다시 실행 가능하며, 제거는 `./install.sh --uninstall`.

> [`jq`](https://jqlang.github.io/jq/)가 필요합니다(`brew install jq`).

## CLI 명령어(`cluo` / `btw`)

Claude Code 안에서 토큰 소비가 없는 `!` 접두사로 실행하세요. 예: `! btw stats`.

| 명령어 | 효과 |
|---|---|
| `btw stats` | 점수판 표시(언어, 정답률, 연승, 배운 단어) |
| `btw answer <답>` | **가장 최근의** 대기 중인 문제에 아웃오브밴드로 답변(즉시 채점) |
| `btw pending` | 미답 문제 목록 표시 |
| `cluo lang <언어>` | 연습할 대상 언어 설정(예: `cluo lang Japanese`) |
| `cluo native <언어>` | 모국어 설정(기본 Chinese) |
| `cluo on` / `cluo off` | 동반자 켜기 / 끄기 |
| `cluo preset chill\|normal\|hardcore` | `chill` = 작업당 20%; `normal`/`hardcore` = 매 작업 |
| `cluo set mode every\|freq\|chance` | 트리거 모드 |
| `cluo set freq <N>` | `freq` 모드에서 N개 프롬프트마다 출제 |
| `cluo set chance <0-100>` | `chance` 모드에서 프롬프트당 확률 % |
| `cluo reset` | 점수판 초기화(설정은 유지) |
| `cluo ask <답> [설명] [문제]` · `cluo grade correct\|wrong` · `cluo word <단어>` | Claude가 출제/채점 시 호출(pending은 큐로 여러 문제가 충돌하지 않음) |

## 언어

어떤 언어든 연습 가능 —— 대상 언어는 Claude에 전달되는 라벨일 뿐입니다:

```
cluo lang English      # 기본
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # Claude가 이해할 수 있는 것이면 무엇이든
cluo native Chinese    # 표현 노트용 모국어
```

## 트리거 모드

- **every**(기본)—— 실질적인 작업마다 "btw".
- **freq** —— `N`개 프롬프트마다 출제.
- **chance** —— 프롬프트마다 `chance`% 확률로 출제(룰렛).

## 탈출구 & fail-open

- `!`로 시작하는 프롬프트(셸 명령)는 절대 건드리지 않습니다.
- `jq`가 없거나, 동반자가 비활성화되었거나, 무언가 오류가 나면 훅은 **fail open** —— 프롬프트는 반드시 전달됩니다.

## 상태

점수판과 설정은 `~/.claude/cluolingo/state.json`(또는 `$CLAUDE_CONFIG_DIR/cluolingo/`)에 저장됩니다.

## 라이선스

MIT
