# 🦉 Cluolingo

> **Claude × Duolingo** —— pratique um idioma enquanto sua IA faz o trabalho. Um companheiro **que não bloqueia** para o [Claude Code](https://claude.com/claude-code).

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · **Português**

Um princípio de design deliberado: **ele nunca te bloqueia.**

Cluolingo envia sua tarefa real para um **agente em segundo plano** e então insere casualmente uma pergunta de idioma no chat —— *"quiz rápido enquanto isso roda…"*. No instante em que o trabalho termina, você recebe o resultado —— tendo respondido ou não. Um companheiro gentil, nunca um portão.

Multilíngue: pratique inglês por padrão, ou `cluo lang Japanese` / `cluo lang Spanish` / qualquer coisa.

## Como funciona

Um hook `UserPromptSubmit` injeta contexto de comportamento em cada prompt. Para uma tarefa substancial, o Claude é instruído a:

1. **Reescrever** seu pedido em um **{idioma-alvo}** refinado + 2–4 notas de fraseado (o bloco «_Idioma_ version»).
2. **Despachar** o trabalho real para um agente em segundo plano para rodar enquanto você conversa.
3. **Inserir um quiz rápido** —— uma pergunta de preencher a lacuna ou de múltipla escolha a partir da reescrita.
4. **Nunca esperar.** Quando a tarefa em segundo plano retorna, o resultado é exibido independentemente da pergunta. O aparte é prática opcional, não um portão.

Quando você responde, seu placar é atualizado via a CLI `cluo`.

```
Você ▸ 幫我把這個列表加上分頁
IA   ▸ English version
         Rewrite: "Add pagination to this list for me."
         Phrasing notes: 分頁 → pagination (não "paging")
       Quick quiz: o ato de dividir uma lista em páginas se chama p_________?
       🔧 Comecei o trabalho de paginação em segundo plano.
       (responda com `! cluo answer pagination` ou apenas responda —— o código chega quando estiver pronto)
```

## Bônus: a reescrita é um teste de compreensão grátis

Você dispara um prompt rápido e meio cru; antes de começar o trabalho, o Cluolingo devolve uma reescrita polida no idioma que você pratica. Se você lê o bastante, essa reescrita mostra na hora **se a IA entendeu mesmo o seu pedido** —— assim você pega um mal-entendido cedo, antes de ela sair construindo a coisa errada. A reescrita faz dois papéis: prática do idioma **e** um espelho da compreensão da IA.

## Responder sem atrapalhar seu fluxo

Três formas —— todas dão o veredito + a resposta certa; diferem na *explicação* e em se *pontuam*:

| Como | Explicação | Pontua? |
|---|---|---|
| `! cluo answer pagination` | uma frase fixa salva quando a pergunta foi feita —— local, zero tokens, não entra no chat | ✅ |
| responda `pagination` no chat | o Claude corrige sua resposta ao vivo (aponta *onde* você errou); custa um pouco | ✅ |
| `/btw pagination` embutido | ao vivo como uma resposta de chat, mas roda num fork somente leitura | ❌ |

`cluo` é a CLI completa —— execute-a com o prefixo `!` (ex.: `! cluo stats`).

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

Isso vincula a CLI `cluo` ao seu PATH e conecta o hook ao `~/.claude/settings.json`. Reexecute quando quiser; desinstale com `./install.sh --uninstall`.

> Requer [`jq`](https://jqlang.github.io/jq/) (`brew install jq`).

## A CLI (`cluo`)

Execute com o prefixo de shell `!` (zero tokens) dentro do Claude Code, ex.: `! cluo stats`.

| Comando | Efeito |
|---|---|
| `cluo answer <resposta>` | Responde **a pergunta pendente mais recente** (pontuada na hora) |
| `cluo answer @N [answer]` | Responde uma pergunta **específica** pelo número listado (base 1, conforme exibido em `pending`/visualização) — permite responder as mais antigas primeiro |
| `cluo answer --all [@N] [answer]` | Esta chamada: abrange o backlog de **todas** as sessões (elimina perguntas órfãs de sessões encerradas) |
| `cluo answer --mine [@N] [answer]` | Esta chamada: limita a **esta** sessão (sobrescreve `scope=all`) |
| `cluo pending [--all]` | Lista suas perguntas em aberto, cada uma numerada com `@N`. `--all` = todas as sessões, cada uma com o seu session id |
| `cluo stats` | Mostra o placar (idioma, precisão, sequência, palavras aprendidas) |
| `cluo lang <idioma>` | Define o idioma-alvo de prática (ex.: `cluo lang Japanese`) |
| `cluo native <idioma>` | Define seu idioma nativo (padrão Chinese) |
| `cluo on` / `cluo off` | Ativa / desativa o companheiro |
| `cluo preset chill\|normal\|hardcore` | `chill` = 20% por tarefa; `normal`/`hardcore` = toda tarefa |
| `cluo set mode every\|freq\|chance` | Modo de acionamento |
| `cluo set freq <N>` | No modo `freq`, pergunta a cada N prompts |
| `cluo set chance <0-100>` | No modo `chance`, probabilidade % por prompt |
| `cluo set scope all\|session` | Escopo padrão para `cluo answer`. `all` = abrange todas as sessões (sem precisar de `--all`); `session` = só esta sessão (padrão) |
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

- **every** (padrão) —— toda tarefa substancial recebe um quiz rápido.
- **freq** —— pergunta a cada `N` prompts.
- **chance** —— pergunta com `chance`% de probabilidade por prompt (roleta).

## Saída de emergência e fail-open

- Prompts que começam com `!` (comandos de shell) nunca são tocados.
- Se faltar `jq`, o companheiro estiver desativado, ou algo der erro, o hook **falha em aberto (fail open)** —— seu prompt sempre passa.

## Estado

O placar e as configurações ficam em `~/.claude/cluolingo/state.json` (ou `$CLAUDE_CONFIG_DIR/cluolingo/`).

## Licença

MIT
