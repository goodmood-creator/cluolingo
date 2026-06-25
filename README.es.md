# 🦉 Cluolingo

> **Claude × Duolingo** —— practica un idioma mientras tu IA hace el trabajo. Un compañero **que no bloquea** para [Claude Code](https://claude.com/claude-code).

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español** · [Português](README.pt.md)

Un principio de diseño deliberado: **nunca te bloquea.**

Cluolingo envía tu tarea real a un **agente en segundo plano** y luego desliza con naturalidad una pregunta de idioma en el chat —— *"quiz rápido mientras eso corre…"*. En cuanto el trabajo termina, recibes el resultado —— hayas respondido o no. Un compañero amable, nunca una barrera.

Multilingüe: practica inglés por defecto, o `cluo lang Japanese` / `cluo lang Spanish` / lo que sea.

## Cómo funciona

Un hook `UserPromptSubmit` inyecta contexto de comportamiento en cada prompt. Para una tarea sustancial, se le indica a Claude que:

1. **Reescriba** tu petición en un **{idioma objetivo}** pulido + 2–4 notas de fraseo (el bloque «_Idioma_ version»).
2. **Despache** el trabajo real a un agente en segundo plano para que corra mientras hablas.
3. **Cuela un quiz rápido** —— una pregunta de rellenar el hueco o de opción múltiple a partir de la reescritura.
4. **Nunca espere.** Cuando la tarea en segundo plano responde, el resultado se muestra sin importar la pregunta. El inciso es práctica opcional, no una barrera.

Cuando respondes, tu marcador se actualiza vía la CLI `cluo`.

```
Tú ▸ 幫我把這個列表加上分頁
IA ▸ English version
       Rewrite: "Add pagination to this list for me."
       Phrasing notes: 分頁 → pagination (no "paging")
     Quick quiz: el acto de dividir una lista en páginas se llama p_________?
     🔧 Empecé el trabajo de paginación en segundo plano.
     (responde con `! cluo answer pagination` o simplemente contesta —— el código llega cuando esté listo)
```

## Extra: la reescritura es un chequeo de comprensión gratis

Lanzas un prompt rápido y a medio formar; antes de ponerse a trabajar, Cluolingo te devuelve una reescritura pulida en el idioma que practicas. Si lees lo suficiente, esa reescritura te muestra al instante **si la IA entendió de verdad tu petición** —— así detectas un malentendido temprano, antes de que se lance a construir lo que no era. La reescritura hace doble trabajo: práctica de idioma **y** un espejo de la comprensión de la IA.

## Responder sin interrumpir tu flujo

Tres formas —— todas dan el veredicto + la respuesta correcta; difieren en la *explicación* y en si *puntúan*:

| Cómo | Explicación | ¿Puntúa? |
|---|---|---|
| `! cluo answer pagination` | una frase fija guardada al plantear la pregunta —— local, cero tokens, no entra en el chat | ✅ |
| responde `pagination` en el chat | Claude corrige tu respuesta en vivo (señala *en qué* fallaste); cuesta un poco | ✅ |
| `/btw pagination` integrado | en vivo como una respuesta de chat, pero corre en un fork de solo lectura | ❌ |

`cluo` es la CLI completa —— ejecútala con el prefijo `!` (p. ej. `! cluo stats`).

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

Ejecuta con el prefijo de shell `!` (cero tokens) dentro de Claude Code, p. ej. `! cluo stats`.

| Comando | Efecto |
|---|---|
| `cluo answer <respuesta>` | Responde **la pregunta pendiente más reciente** (puntuada al instante) |
| `cluo answer @N [answer]` | Responde una pregunta **específica** por su número listado (base 1, según `pending`/vista previa) — permite responder las más antiguas primero |
| `cluo answer --all [@N] [answer]` | Esta llamada: abarca el pendiente de **todas** las sesiones (limpia preguntas huérfanas de sesiones terminadas) |
| `cluo answer --mine [@N] [answer]` | Esta llamada: limita a **esta** sesión (anula `scope=all`) |
| `cluo pending [--all]` | Lista tus preguntas abiertas, cada una numerada con `@N`. `--all` = las de todas las sesiones, etiquetadas con su session id |
| `cluo stats` | Muestra el marcador (idioma, precisión, racha, palabras aprendidas) |
| `cluo lang <idioma>` | Define el idioma objetivo de práctica (p. ej. `cluo lang Japanese`) |
| `cluo native <idioma>` | Define tu idioma nativo (por defecto Chinese) |
| `cluo on` / `cluo off` | Activa / desactiva el compañero |
| `cluo preset chill\|normal\|hardcore` | `chill` = 20% por tarea; `normal`/`hardcore` = cada tarea |
| `cluo set mode every\|freq\|chance` | Modo de activación |
| `cluo set freq <N>` | En modo `freq`, pregunta cada N prompts |
| `cluo set chance <0-100>` | En modo `chance`, probabilidad % por prompt |
| `cluo set scope all\|session` | Ámbito por defecto para `cluo answer`. `all` = abarca todas las sesiones (sin necesidad de `--all`); `session` = solo esta sesión (por defecto) |
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

- **every** (por defecto) —— cada tarea sustancial recibe un quiz rápido.
- **freq** —— pregunta cada `N` prompts.
- **chance** —— pregunta con `chance`% de probabilidad por prompt (ruleta).

## Vía de escape y fail-open

- Los prompts que empiezan con `!` (comandos de shell) nunca se tocan.
- Si falta `jq`, el compañero está desactivado, o algo falla, el hook **falla en abierto (fail open)** —— tu prompt siempre pasa.

## Estado

El marcador y los ajustes viven en `~/.claude/cluolingo/state.json` (o `$CLAUDE_CONFIG_DIR/cluolingo/`).

## Licencia

MIT
