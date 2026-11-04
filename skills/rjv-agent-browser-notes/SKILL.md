---
name: rjv-agent-browser-notes
description: "Field notes that sit ON TOP of the vendor agent-browser skill — the failures it does not cover. Load together with `agent-browser` whenever driving a real React app (Radix/shadcn, Inertia, react-hook-form) or QA-ing a feature end to end. Triggers: clicks report success but nothing happens, hover or tooltips never fire, `fill` does not stick, a Select or Tab will not open, a menu picks the wrong row, the cart or form silently empties, `doctor` says pass but the page is dead, dev-server reloads wipe state, several agents share one browser."
---

# agent-browser: what the vendor skill leaves out

Read the vendor skill first (`agent-browser skills get core`). Each rule below cost a real
debugging session; two produced false bug reports.

## Find your symptom

| Symptom | Go to |
|---|---|
| Every command says `✓ Done` but nothing changes; hover or tooltips never fire; `doctor` passes | §1 dead session |
| Keyboard input seems ignored | §1 keys |
| Resize did nothing | §1 viewport |
| A Select, Tab, Popover or Combobox will not open | §2 Radix triggers |
| Click reports `covered by <overlay>` in a dialog | §2 scroll first |
| `fill` does not stick, or a date input stays empty | §2 native setter |
| A menu picks the wrong row, or the cart or form silently empties | §2 two `eval`s; §3 closed menus |
| React breaks for the rest of the run | §2 no `.remove()` |
| Text read from the page misses what was typed | §3 `.value` |
| A field looks like a server error, or a toast looks like success | §3 capture responses, check the datastore |
| Form state vanished on its own | §4 Vite reload |
| A 500 that does not repeat; timestamps look hours off | §4 noise |
| Several agents share one browser | §4 sessions |

## 1. Prove input reaches the page before blaming the app

A dead session returns `✓ Done` to every command while no real input lands. `doctor` still
passes. Run this before filing "hover doesn't work", "overlay swallows clicks" or "clicking X
does nothing":

```bash
agent-browser eval '(()=>{window.__s=[];["pointermove","pointerover"].forEach(n=>document.addEventListener(n,e=>window.__s.push(n),true));return "ok"})()'
agent-browser mouse move 500 400; sleep 1; agent-browser mouse move 520 420; sleep 1
agent-browser eval '(()=>JSON.stringify(window.__s.slice(0,3)))()'   # [] = dead
```

Dead: `agent-browser close`, reopen, log back in.

**Keys** can fail on their own. Push `e.key` from a `keydown` listener into `window.__k`, press
`Tab`, read it back. Empty means every keyboard conclusion is void.

**Viewport**: confirm any state you set by reading it back in the page; the exit code proves
nothing. Resizing is `set viewport <w> <h>`; bare `viewport` is a silent no-op. Check
`window.innerWidth`.

## 2. Clicking and typing in React

- Ordinary `<button>`: JS `.click()` in `eval` is fine.
- Radix / shadcn triggers (Select, Tabs, Popover, Combobox) ignore `.click()`. Use a snapshot
  ref, or dispatch the pointer sequence:

```bash
agent-browser eval '(()=>{const e=document.querySelector(SEL); e.scrollIntoView({block:"center"});
["pointerdown","mousedown","pointerup","mouseup","click"].forEach(t=>
  e.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,pointerId:1,button:0,buttons:1})));
return "clicked"})()'
```

- Rows below the fold in a dialog report `covered by <overlay>`. `scrollIntoView` first.
- react-hook-form ignores `fill`, and `fill` never sets `type="date"`. Use the native setter:

```bash
agent-browser eval '(()=>{const el=document.querySelector(SEL);
Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,"value").set.call(el,VALUE);
["input","change"].forEach(t=>el.dispatchEvent(new Event(t,{bubbles:true}))); return el.value})()'
```

- Pick and confirm in two `eval`s with `sleep 2` between. One `eval` races React and
  empties the cart.
- To undo a DOM change, reload the page. Calling `.remove()` on a node breaks React for the
  rest of the run.

## 3. Reading state without faking bugs

- `innerText` leaves out input values. Read `.value`, by `data-test`.
- Closed menus and dialogs stay mounted. Scope queries to `[data-state=open]`.
- To tell whether a red outline came from the server, hook `XMLHttpRequest` in `eval`, push
  responses with status >= 400 into `window.__cap`, and read that. The outline alone proves
  nothing.
- A green toast only means a 200. Check the datastore with a small inspect script after every
  send.

## 4. Noise that looks like a bug

- A Vite full reload (`[vite] connecting...` in the console) wipes form state.
- Another agent's half-saved file causes passing 500s. Re-run the request once; report the
  500 only if it repeats.
- Logs are often in UTC.
- Give each agent its own session: `AGENT_BROWSER_SESSION=<name>`.

## 5. Keep a driver file

One sourced shell file per project: base URLs, fixture ids, login, navigation, and the helpers
above. A run that starts with `source ./ab.sh` is reproducible.
