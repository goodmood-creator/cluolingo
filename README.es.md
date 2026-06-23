# 🦉 Cluolingo

> **Claude × Duolingo** —— practica un idioma mientras tu IA hace el trabajo. Un compañero **que no bloquea** para [Claude Code](https://claude.com/claude-code).

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español** · [Português](README.pt.md)

Un principio de diseño deliberado: **nunca te bloquea.**

Cluolingo envía tu tarea real a un **agente en segundo plano** y luego desliza con naturalidad una pregunta de idioma en el chat —— *"btw, mientras eso corre, una rapidita…"*. En cuanto el trabajo termina, recibes el resultado —— hayas respondido o no. Un compañero amable, nunca una barrera.

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
     (responde con `/btw pagination`, o `! cluo answer pagination`, o simplemente contesta —— el código llega cuando esté listo)
```

## Responder sin interrumpir tu flujo

Tres formas, elige según el momento:

- **`/btw pagination` (fácil):** el comando de barra. Claude lo corrige, actualiza tu racha y añade una explicación de una línea. Visible en el menú `/`; pasa por el chat, así que cuesta un poco.
- **`! cluo answer pagination` (cero interrupción):** el prefijo de shell `!` corre en local, no cuesta tokens y nunca entra en la conversación, así que no contamina tu tarea principal. La CLI lo corrige al instante.
- **Responde `pagination` en el chat:** Claude lo corrige con calidez y una explicación de una línea. Un poco más de contexto, pero aprendes más.

`/btw` es el atajo de comando de barra para responder; `cluo` es la CLI completa —— ejecútala con el prefijo `!` (p. ej. `! cluo stats`).

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

Esto enlaza la CLI `cluo` en tu PATH y conecta el hook en `~/.claude/settings.json`. Reejecuta cuando quieras; desinstala con `./install.sh --uninstall`.

> Requiere [`jq`](https://jqlang.github.io/jq/) (`brew install jq`).

## La CLI (`cluo`)

Ejecuta con el prefijo de shell `!` (cero tokens) dentro de Claude Code, p. ej. `! cluo stats`. (Para responder un quiz, el comando de barra `/btw` de arriba suele ser más cómodo.)

| Comando | Efecto |
|---|---|
| `cluo answer <respuesta>` | Responde **la pregunta pendiente más reciente** (el comando `/btw <respuesta>` hace lo mismo) |
| `cluo pending` | Lista las preguntas abiertas (sin responder) |
| `cluo stats` | Muestra el marcador (idioma, precisión, racha, palabras aprendidas) |
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
