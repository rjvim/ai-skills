---
name: rjv-agent-browser-notes
description: "Field notes that sit ON TOP of the vendor agent-browser skill — the failures it does not cover. Load together with `agent-browser` whenever driving a real React app (Radix/shadcn, Inertia, react-hook-form) or QA-ing a feature end to end. Triggers: clicks report success but nothing happens, hover or tooltips never fire, `fill` does not stick, a Select or Tab will not open, a menu picks the wrong row, the cart or form silently empties, `doctor` says pass but the page is dead, dev-server reloads wipe state, several agents share one browser."
---

# agent-browser — what the vendor skill leaves out

The vendor skill (`agent-browser skills get core`) is the reference: refs, commands,
troubleshooting for stale refs, overlay-covered clicks, key-event interception. **Read it first.**

These are the failures it does not name. Every one below cost a real debugging session, and two of
them produced *false bug reports* against the application before being understood.

## 0. RULE ZERO — a dead session lies to you

**Before concluding anything about the app, prove input still reaches the page.**

A session can reach a state where every command returns `✓ Done`, `snapshot` and `eval` keep
working, and **no real input lands**. Clicks do nothing. Hover fires nothing. Radix exit
animations never run, so closed dialog overlays never unmount and then block everything else.

`agent-browser doctor` does **not** catch this — it checks the daemon and pid, and happily prints
`pass Session <name> (pid …)` while the page is dead.

```bash
# is the session alive? empty output = dead.
agent-browser eval '(()=>{window.__s=[];["pointermove","pointerover"].forEach(n=>document.addEventListener(n,e=>window.__s.push(n),true));return "ok"})()'
agent-browser mouse move 500 400; sleep 1; agent-browser mouse move 520 420; sleep 1
agent-browser eval '(()=>JSON.stringify(window.__s.slice(0,3)))()'
# ["pointerover","pointermove","pointermove"]  → alive
# []                                           → dead: close and reopen, then log back in
```

Fix is always the same: `agent-browser close`, reopen, re-authenticate.

**Never file these without running the probe first** — they are symptoms of a dead session, not bugs:

- "the tool cannot hover / tooltips don't work"
- "the app leaks dialog overlays that swallow clicks"
- "clicking X does nothing"

## 0b. A command that isn't a command returns nothing and looks fine

Two ways a check can silently test nothing. Both produced confident wrong conclusions in one session.

- **`press` may deliver no key events at all.** Clicks worked; keys did not. Three `Tab`s "moved"
  focus nowhere and the natural read is "focus is trapped" — the truth was that nothing arrived.
  Probe before believing any keyboard result:

```bash
agent-browser eval '(()=>{window.__k=[];document.addEventListener("keydown",e=>window.__k.push(e.key),true);return "ok"})()'
agent-browser press Tab; agent-browser eval '(()=>JSON.stringify(window.__k))()'
# []  → keys are not arriving. Every keyboard conclusion you draw is void.
```

- **Wrong sub-command = silent no-op.** Resizing is `agent-browser set viewport <w> <h>`. Bare
  `viewport 390 844` prints `Unknown command` on a line you are not reading and the page stays
  1280 wide — so a "mobile" test runs on desktop and passes for the wrong reason.

**Always confirm the state you think you set**, in the page, not from the CLI's exit code:
`agent-browser eval '(()=>window.innerWidth)()'`.

## 1. The interaction ladder

Try in this order. Each rung costs more than the one above it.

```
   click something
         │
   ┌─────┴─────┐
   ▼           ▼
ordinary    Radix / shadcn
 button      (Select, Tabs,
   │          Popover, Combobox)
   ▼               │
JS .click()   ┌────┴────┐
via eval      ▼         ▼
           ref click  synthetic
           from       PointerEvent
           snapshot   sequence
```

- **Ordinary `<button>`** — a JS `.click()` inside `eval` is fine and fastest.
- **Radix triggers** — a JS `.click()` does nothing. They listen on `pointerdown`. Use a ref from
  `snapshot`, or dispatch the full sequence yourself:

```bash
agent-browser eval '(()=>{const e=document.querySelector(SEL); e.scrollIntoView({block:"center"});
["pointerdown","mousedown","pointerup","mouseup","click"].forEach(t=>
  e.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,pointerId:1,button:0,buttons:1})));
return "clicked"})()'
```

  The synthetic sequence beats a coordinate click when the target sits inside a scrolling table:
  no hit-testing, so nothing can "cover" it.

- **Rows below the fold inside a dialog** report `covered by <overlay>` — the click point maps
  outside the dialog. `scrollIntoView({block:"center"})` first, then click.

## 2. React-controlled inputs ignore `fill`

react-hook-form reads the React value, not the DOM's. Drive the native setter and fire both events:

```bash
agent-browser eval '(()=>{const el=document.querySelector(SEL);
const s=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,"value").set;
s.call(el,VALUE); el.dispatchEvent(new Event("input",{bubbles:true}));
el.dispatchEvent(new Event("change",{bubbles:true})); return el.value})()'
```

Mandatory for `<input type="date">`, which `fill` never sets.

## 3. Reading state — the two mistakes that fake bugs

- **`innerText` does not include input values.** Reading a card's text and concluding "the amount
  did not seed" is wrong; the value lives in `.value`. This produced two false findings in one
  session. Query fields explicitly, by `data-test`.
- **Closed menus stay mounted.** `document.querySelectorAll('[role=option]')` returns the previous
  menu's options too, so you silently act on the wrong row. Scope to the open one:

```js
[...document.querySelectorAll(OPT)].filter(o => o.closest('[data-state=open]')).pop()
```

  Same for dialogs: always query `[role=dialog][data-state=open]`.

## 4. Two ticks, not one

Selecting and confirming in a single `eval` races React — the confirm reads state that has not
committed and you get an empty cart. Split them, with a `sleep` between:

```bash
agent-browser eval '...pick the row...'   # tick 1
sleep 2
agent-browser eval '...click Done...'     # tick 2
```

## 5. Never `.remove()` a DOM node

Ripping out a stuck overlay tears it out from under React; every later render becomes a no-op and
the rest of the run is garbage. Reload the page. Setting an attribute is safe (useful for tagging
the nth match so it can be clicked by selector); removing nodes is not.

## 6. See the real error, not the rendered one

Compact table cells often show a red outline and put the message in a tooltip. Do not guess what
the server said — capture it:

```bash
agent-browser eval '(()=>{window.__cap=[];const O=XMLHttpRequest.prototype.open,S=XMLHttpRequest.prototype.send;
XMLHttpRequest.prototype.open=function(m,u){this.__u=u;return O.apply(this,arguments)};
XMLHttpRequest.prototype.send=function(b){this.addEventListener("load",()=>{
  if(/PATTERN/.test(this.__u)&&this.status>=400) window.__cap.push({s:this.status,b:this.responseText.slice(0,400)})});
return S.apply(this,arguments)}; return "hooked"})()'
```

Then read `window.__cap`. This is how you learn a 422 said "Choose an approved mandate that can
cover this transaction" while the page showed nothing.

To confirm a toast that fades before you can look, observe the container instead of polling:

```js
new MutationObserver(ms => ms.forEach(m => m.addedNodes.forEach(n => window.__t.push(n.textContent))))
  .observe(document.querySelector('section[aria-label*=otification]'), {childList:true, subtree:true})
```

## 7. The screen is not the evidence

A green toast means the request returned 200, nothing more. **Check the datastore.** Several bugs
this method caught were invisible on screen: the right row count with the wrong order type, a plan
saved as a purchase, a cart replaced rather than merged. Write a small inspect script for the
domain object and run it after every send.

## 8. Dev-server and multi-agent noise

- **HMR full reloads wipe in-progress form state.** If a cart empties for no reason, check the
  console for `[vite] connecting...` — that is a reload, not a bug.
- **Another agent editing the repo causes transient 500s.** A compile error in a half-saved file
  surfaces as a failed save in your browser. Re-run before believing it.
- **Log timestamps are often UTC while your clock is local.** A "stale" error may be yours from
  ten seconds ago.
- **Give each agent its own session** — `AGENT_BROWSER_SESSION=<name>` — or two agents fight over
  one tab. `agent-browser session list` shows who is already there.

## 9. Keep a driver file, not ad-hoc commands

One sourced shell file per project, holding: the base URLs and fixture ids, the login helper, the
navigation helpers, `stale`, `restart`, and the click/read helpers above. Put the hard-won rules in
its header as comments. A run that starts with `source ./ab.sh` is reproducible; a run assembled
from remembered one-liners is not.
