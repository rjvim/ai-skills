#!/bin/sh
# ollama-chat.sh <model> <prompt-file> <out-file> [num_ctx] [keep_alive]
# Calls the local Ollama chat API non-streaming; writes content to out-file,
# prints timing stats to stdout. keep_alive (default 2h) keeps the model
# resident between calls so only the first call pays the load time.
# Why not `ollama run`: the CLI emits TTY escape codes into its output even
# with redirected stdout; the HTTP API returns clean text.
MODEL="$1"; PROMPT_FILE="$2"; OUT_FILE="$3"; NUM_CTX="${4:-16384}"; KEEP_ALIVE="${5:-2h}"
python3 - "$MODEL" "$PROMPT_FILE" "$OUT_FILE" "$NUM_CTX" "$KEEP_ALIVE" <<'EOF'
import json, sys, time, urllib.request
model, prompt_file, out_file, num_ctx, keep_alive = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5]
prompt = open(prompt_file).read()
body = json.dumps({
    "model": model, "stream": False, "think": False, "keep_alive": keep_alive,
    "options": {"num_ctx": num_ctx, "temperature": 0.2},
    "messages": [{"role": "user", "content": prompt}],
}).encode()
t0 = time.time()
req = urllib.request.Request("http://localhost:11434/api/chat", data=body,
                             headers={"Content-Type": "application/json"})
resp = json.load(urllib.request.urlopen(req, timeout=3000))
wall = time.time() - t0
open(out_file, "w").write(resp["message"]["content"])
ec, ed = resp.get("eval_count", 0), resp.get("eval_duration", 1)
pc, pd = resp.get("prompt_eval_count", 0), resp.get("prompt_eval_duration", 1)
print(f"wall={wall:.1f}s prompt_tokens={pc} ({pc/(pd/1e9):.0f} tok/s) "
      f"output_tokens={ec} ({ec/(ed/1e9):.1f} tok/s) "
      f"load={resp.get('load_duration',0)/1e9:.1f}s")
EOF
