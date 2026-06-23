# 🦉 Cluolingo

> **Claude × Duolingo** —— practica un idioma mientras tu IA hace el trabajo. Un compañero **que no bloquea** para [Claude Code](https://claude.com/claude-code).

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español** · [Português](README.pt.md)

Inspirado en [workout-gate](https://github.com/BotchetDig/workout-gate), pero con una inversión deliberada: **nunca te bloquea.**

- **workout-gate** congela tu prompt hasta que haces flexiones frente a la webcam. Una barrera dura.
- **Cluolingo** envía tu tarea real a un **agente en segundo plano** y luego desliza con naturalidad una pregunta de idioma en el chat —— *"btw, mientras eso corre, una rapidita…"*. En cuanto el trabajo termina, recibes el resultado —— hayas respondido o no. Un compañero amable, nunca una barrera.

Multilingüe: practica inglés por defecto, o `cluo lang Japanese` / `cluo lang Spanish` / lo que sea.

## Cómo funciona

Un hook `UserPromptSubmit` inyecta contexto de comportamiento en cada prompt. Para una tarea sustancial, se le indica a Claude que:

1. **Reescriba** tu petición en un **{idioma objetivo}** pulido + 2–4 notas de fraseo (el bloque «_Idioma_ version»).
2. **Despache** el trabajo real a un agente en segundo plano para que corra mientras hablas.
3. **Cuele un "btw"** —— una pregunta de rellenar el hueco o de opción múltiple a partir de la reescritura.
4. **Nunca espere.** Cuando la tarea en segundo plano responde, el resultado se muestra sin importar la pregunta. El inciso es práctica opcional, no una barrera.

Cuando respondes, tu marcador se actualiza vía la CLI `cluo`.

```
Tú ▸ 幫我把這個列表加上分頁
IA ▸ English version
       Rewrite: "Add pagination to this list for me."
       Notes: 分頁 → pagination (no "paging")…
     🔧 Empecé el trabajo de paginación en segundo plano.
     btw, mientras corre —— una rapidita:
       el acto de dividir una lista en páginas se llama p_________?
     (responde con `! btw answer pagination`, o simplemente contesta —— el código llega cuando esté listo)
```

## Responder sin interrumpir tu flujo

Dos formas, elige según el momento:

- **Fuera de banda (recomendado, cero interrupción):** `! btw answer pagination`. El prefijo de shell `!` no cuesta tokens y nunca entra en la conversación, así que no contamina tu tarea principal. La CLI corrige la respuesta y actualiza tu racha al instante.
- **En el chat (cuando quieres la explicación):** simplemente responde `pagination`. Claude lo corrige con calidez y una explicación de una línea. Un poco más de contexto, pero aprendes más.

`btw` y `cluo` son **el mismo comando** —— usa el que se lea mejor (`! btw answer …`, `! cluo stats`).

## Instalación

### Como plugin de Claude Code (recomendado)

```
/plugin marketplace add goodmood-creator/cluolingo
/plugin install cluolingo@cluolingo
```

### Instalación global (manual)

```
git clone https://github.com/goodmood-creator/cluolingo.git
cd cluolingo
./install.sh
```

Esto enlaza la CLI `cluo` + `btw` en tu PATH y conecta el hook en `~/.claude/settings.json`. Reejecuta cuando quieras; desinstala con `./install.sh --uninstall`.

> Requiere [`jq`](https://jqlang.github.io/jq/) (`brew install jq`).

## La CLI (`cluo` / `btw`)

Ejecuta con el prefijo de shell `!` (cero tokens) dentro de Claude Code, p. ej. `! btw stats`.

| Comando | Efecto |
|---|---|
| `btw stats` | Muestra el marcador (idioma, precisión, racha, palabras aprendidas) |
| `btw answer <respuesta>` | Responde **la pregunta pendiente más reciente** fuera de banda (puntuada al instante) |
| `btw pending` | Lista las preguntas abiertas (sin responder) |
| `cluo lang <idioma>` | Define el idioma objetivo de práctica (p. ej. `cluo lang Japanese`) |
| `cluo native <idioma>` | Define tu idioma nativo (por defecto Chinese) |
| `cluo on` / `cluo off` | Activa / desactiva el compañero |
| `cluo preset chill\|normal\|hardcore` | `chill` = 20% por tarea; `normal`/`hardcore` = cada tarea |
| `cluo set mode every\|freq\|chance` | Modo de activación |
| `cluo set freq <N>` | En modo `freq`, pregunta cada N prompts |
| `cluo set chance <0-100>` | En modo `chance`, probabilidad % por prompt |
| `cluo reset` | Reinicia el marcador (conserva los ajustes) |
| `cluo ask <respuesta> [explicación] [pregunta]` · `cluo grade correct\|wrong` · `cluo word <texto>` | Llamado por Claude al plantear/corregir una pregunta (pending es una cola) |

## Idiomas

Practica cualquier idioma —— el objetivo es solo una etiqueta que se le pasa a Claude:

```
cluo lang English      # por defecto
cluo lang Japanese
cluo lang Spanish
cluo lang 日本語         # lo que Claude entienda
cluo native Chinese    # tu idioma nativo para las notas de fraseo
```

## Modos de activación

- **every** (por defecto) —— cada tarea sustancial recibe un "btw".
- **freq** —— pregunta cada `N` prompts.
- **chance** —— pregunta con `chance`% de probabilidad por prompt (ruleta).

## Vía de escape y fail-open

- Los prompts que empiezan con `!` (comandos de shell) nunca se tocan.
- Si falta `jq`, el compañero está desactivado, o algo falla, el hook **falla en abierto (fail open)** —— tu prompt siempre pasa.

## Estado

El marcador y los ajustes viven en `~/.claude/cluolingo/state.json` (o `$CLAUDE_CONFIG_DIR/cluolingo/`).

## Licencia

MIT
