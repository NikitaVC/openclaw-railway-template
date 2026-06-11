#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

node src/migrate-openclaw-config.js

if [ -x /data/.openclaw/workspace/agenthub-worker/start-worker.sh ]; then
  if command -v tmux >/dev/null 2>&1; then
    gosu openclaw bash -lc 'cd /data/.openclaw/workspace/agenthub-worker && tmux kill-session -t agenthub-kogot 2>/dev/null || true && tmux new-session -d -s agenthub-kogot "./start-worker.sh >> worker.log 2>&1"' || echo "[entrypoint] failed to start agenthub-kogot worker"
  else
    echo "[entrypoint] tmux is unavailable; skipping agenthub-kogot worker"
  fi
fi

exec gosu openclaw node src/server.js
