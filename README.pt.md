# 🦉 Cluolingo

> **Claude × Duolingo** —— pratique um idioma enquanto sua IA faz o trabalho. Um companheiro **que não bloqueia** para o [Claude Code](https://claude.com/claude-code).

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · **Português**

Um princípio de design deliberado: **ele nunca te bloqueia.**

Cluolingo envia sua tarefa real para um **agente em segundo plano** e então insere casualmente uma pergunta de idioma no chat —— *"btw, enquanto isso roda, uma rapidinha…"*. No instante em que o trabalho termina, você recebe o resultado —— tendo respondido ou não. Um companheiro gentil, nunca um portão.

Multilíngue: pratique inglês por padrão, ou `cluo lang Japanese` / `cluo lang Spanish` / qualquer coisa.

## Como funciona

Um hook `UserPromptSubmit` injeta contexto de comportamento em cada prompt. Para uma tarefa substancial, o Claude é instruído a:

1. **Reescrever** seu pedido em um **{idioma-alvo}** refinado + 2–4 notas de fraseado (o bloco «_Idioma_ version»).
2. **Despachar** o trabalho real para um agente em segundo plano para rodar enquanto você conversa.
3. **Inserir um "btw"** —— uma pergunta de preencher a lacuna ou de múltipla escolha a partir da reescrita.
4. **Nunca esperar.** Quando a tarefa em segundo plano retorna, o resultado é exibido independentemente da pergunta. O aparte é prática opcional, não um portão.

Quando você responde, seu placar é atualizado via a CLI `cluo`.

```
Você ▸ 幫我把這個列表加上分頁
IA   ▸ English version
         Rewrite: "Add pagination to this list for me."
         Notes: 分頁 → pagination (não "paging")…
       🔧 Comecei o trabalho de paginação em segundo plano.
       btw, enquanto roda —— uma rapidinha:
         o ato de dividir uma lista em páginas se chama p_________?
       (responda com `! btw answer pagination`, ou apenas responda —— o código chega quando estiver pronto)
```

## Responder sem atrapalhar seu fluxo

Duas formas, escolha conforme o momento:

- **Fora de banda (recomendado, zero interrupção):** `! btw answer pagination`. O prefixo de shell `!` não custa tokens e nunca entra na conversa, então não polui sua tarefa principal. A CLI confere a resposta e atualiza sua sequência na hora.
- **No chat (quando você quer a explicação):** apenas responda `pagination`. O Claude corrige com simpatia e uma explicação de uma linha. Um pouco mais de contexto, mas você aprende mais.

`btw` e `cluo` são **o mesmo comando** —— use o que ler melhor (`! btw answer …`, `! cluo stats`).

## Instalação

### Como plugin do Claude Code (recomendado)

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### Instalação global (manual)

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

Isso vincula a CLI `cluo` + `btw` ao seu PATH e conecta o hook ao `~/.claude/settings.json`. Reexecute quando quiser; desinstale com `./install.sh --uninstall`.

> Requer [`jq`](https://jqlang.github.io/jq/) (`brew install jq`).

## A CLI (`cluo` / `btw`)

Execute com o prefixo de shell `!` (zero tokens) dentro do Claude Code, ex.: `! btw stats`.

| Comando | Efeito |
|---|---|
| `btw stats` | Mostra o placar (idioma, precisão, sequência, palavras aprendidas) |
| `btw answer <resposta>` | Responde **a pergunta pendente mais recente** fora de banda (pontuada na hora) |
| `btw pending` | Lista as perguntas em aberto (não respondidas) |
| `cluo lang <idioma>` | Define o idioma-alvo de prática (ex.: `cluo lang Japanese`) |
| `cluo native <idioma>` | Define seu idioma nativo (padrão Chinese) |
| `cluo on` / `cluo off` | Ativa / desativa o companheiro |
| `cluo preset chill\|normal\|hardcore` | `chill` = 20% por tarefa; `normal`/`hardcore` = toda tarefa |
| `cluo set mode every\|freq\|chance` | Modo de acionamento |
| `cluo set freq <N>` | No modo `freq`, pergunta a cada N prompts |
| `cluo set chance <0-100>` | No modo `chance`, probabilidade % por prompt |
| `cluo reset` | Reinicia o placar (mantém as configurações) |
| `cluo ask <resposta> [explicação] [pergunta]` · `cluo grade correct\|wrong` · `cluo word <texto>` | Chamado pelo Claude ao propor/corrigir uma pergunta (pending é uma fila) |

## Idiomas

Pratique qualquer idioma —— o alvo é apenas um rótulo passado ao Claude:

```
cluo lang English      # padrão
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # o que o Claude entender
cluo native Chinese    # seu idioma nativo para as notas de fraseado
```

## Modos de acionamento

- **every** (padrão) —— toda tarefa substancial recebe um "btw".
- **freq** —— pergunta a cada `N` prompts.
- **chance** —— pergunta com `chance`% de probabilidade por prompt (roleta).

## Saída de emergência e fail-open

- Prompts que começam com `!` (comandos de shell) nunca são tocados.
- Se faltar `jq`, o companheiro estiver desativado, ou algo der erro, o hook **falha em aberto (fail open)** —— seu prompt sempre passa.

## Estado

O placar e as configurações ficam em `~/.claude/cluolingo/state.json` (ou `$CLAUDE_CONFIG_DIR/cluolingo/`).

## Licença

MIT
