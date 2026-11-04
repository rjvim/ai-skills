#!/usr/bin/env bash
# opencode-watch.sh: run one opencode task under a liveness watcher.
#
# Usage: opencode-watch.sh <dir> <prompt-file> <result-file> <cap-minutes> [text|repo]
#
#   dir          repo mode: the repo opencode works in. text mode: ignored; opencode
#                runs in a fresh empty directory, because even without --auto it
#                reads files and runs shell commands in its working directory.
#   prompt-file  the brief
#   result-file  absolute path for the answer. If opencode did not write it, the
#                script fills it from the run's final text. Non-empty means ok.
#   cap-minutes  hard ceiling per model attempt
#   mode         text (default): no auto-approve, empty sandbox dir.
#                repo: --auto in <dir>; the git tree is fingerprinted before and after.
#
# Every stdout line is one event, so a caller can stream it (Claude Code Monitor):
#   START model=.. pid=..
#   ALIVE model=.. min=.. log=..          every OPENCODE_HEARTBEAT_MIN minutes (default 2)
#   STALL model=.. silent=N               a check saw no sign of life
#   KILL  model=.. reason=silent|cap
#   EXIT  model=.. code=.. secs=..
#   DONE  status=ok|failed model=.. secs=.. result=.. tree=unchanged|CHANGED|n/a
#
# Alive means any of these changed since the last check: the JSON event log size,
# the result file, opencode's database WAL, or the CPU time of opencode's process
# tree. The JSON log only grows at step boundaries, so a long single answer can be
# quiet there while CPU time still moves.
#
# Env: OPENCODE_CHECK_SEC (default 30), OPENCODE_SILENT_MAX (default 4 checks),
#      OPENCODE_MODELS (default "opencode-go/deepseek-v4.1-flash opencode-go/minimax-m3").
set -u
dir=$1 prompt_file=$2 result=$3 cap_min=$4 mode=${5:-text}
check=${OPENCODE_CHECK_SEC:-30}
silent_max=${OPENCODE_SILENT_MAX:-4}
beat_min=${OPENCODE_HEARTBEAT_MIN:-2}
models=${OPENCODE_MODELS:-"opencode-go/deepseek-v4.1-flash opencode-go/minimax-m3"}
wal=~/.local/share/opencode/opencode.db-wal
log="$result.log"

[ "$mode" = text ] && dir=$(mktemp -d "${TMPDIR:-/tmp}/opencode-text.XXXXXX")
[ -d "$dir" ] || { echo "DONE status=failed reason=no-dir"; exit 2; }
[ -s "$prompt_file" ] || { echo "DONE status=failed reason=no-prompt"; exit 2; }
case "$mode" in text) auto="" ;; repo) auto="--auto" ;; *) echo "DONE status=failed reason=bad-mode"; exit 2 ;; esac

tree_sig() { [ "$mode" = repo ] || { echo n/a; return; }; (cd "$dir" && { git status --porcelain; git diff; git diff --cached; } 2>/dev/null | md5); }
cpu_of() { # total CPU seconds of pid and its descendants
  local p kids total=0
  for p in $1 $(pgrep -P "$1" 2>/dev/null); do
    t=$(ps -o time= -p "$p" 2>/dev/null | awk -F'[:.]' '{ if (NF==4) print $1*3600+$2*60+$3; else print $1*60+$2 }')
    total=$((total + ${t:-0}))
    for kids in $(pgrep -P "$p" 2>/dev/null); do
      t=$(ps -o time= -p "$kids" 2>/dev/null | awk -F'[:.]' '{ if (NF==4) print $1*3600+$2*60+$3; else print $1*60+$2 }')
      total=$((total + ${t:-0}))
    done
  done
  echo $total
}
kill_tree() { pkill -TERM -P "$1" 2>/dev/null; kill -TERM "$1" 2>/dev/null; sleep 3; pkill -KILL -P "$1" 2>/dev/null; kill -KILL "$1" 2>/dev/null; }

before=$(tree_sig)
prompt=$(cat "$prompt_file")
start_all=$(date +%s); status=failed; used=""
for model in $models; do
  used=$model; : > "$log"; rm -f "$result"
  (cd "$dir" && exec opencode run --standalone $auto --format json -m "$model" --title "watch $(basename "$result")" "$prompt") >> "$log" 2>&1 &
  pid=$!; t0=$(date +%s); last=""; silent=0; next_beat=$((t0 + beat_min * 60))
  echo "START model=$model pid=$pid cap=${cap_min}m"
  while kill -0 "$pid" 2>/dev/null; do
    sleep "$check"
    kill -0 "$pid" 2>/dev/null || break
    now=$(date +%s); el=$((now - t0))
    sig="$(stat -f %z "$log" 2>/dev/null)-$(stat -f %m "$result" 2>/dev/null)-$(stat -f %m $wal 2>/dev/null)-$(cpu_of "$pid")"
    if [ "$sig" = "$last" ]; then silent=$((silent + 1)); echo "STALL model=$model silent=$silent min=$((el / 60))"; else silent=0; fi
    last=$sig
    if [ "$now" -ge "$next_beat" ]; then echo "ALIVE model=$model min=$((el / 60)) log=$(stat -f %z "$log")"; next_beat=$((now + beat_min * 60)); fi
    if [ "$silent" -ge "$silent_max" ]; then echo "KILL model=$model reason=silent"; kill_tree "$pid"; break; fi
    if [ "$el" -ge $((cap_min * 60)) ]; then echo "KILL model=$model reason=cap"; kill_tree "$pid"; break; fi
  done
  wait "$pid" 2>/dev/null; code=$?
  echo "EXIT model=$model code=$code secs=$(( $(date +%s) - t0 ))"
  if [ "$code" -eq 0 ] && [ ! -s "$result" ]; then
    jq -rs '[.[] | select(.type=="text") | .part.text] | last // empty' "$log" > "$result" 2>/dev/null
  fi
  if [ -s "$result" ]; then status=ok; break; fi
done
after=$(tree_sig)
if [ "$before" = n/a ]; then tree=n/a; elif [ "$before" = "$after" ]; then tree=unchanged; else tree=CHANGED; fi
echo "DONE status=$status model=$used secs=$(( $(date +%s) - start_all )) result=$result tree=$tree"
[ "$status" = ok ]
