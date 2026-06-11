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
  gosu openclaw bash -lc 'cd /data/.openclaw/workspace/agenthub-worker && tmux kill-session -t agenthub-kogot 2>/dev/null || true && tmux new-session -d -s agenthub-kogot "./start-worker.sh >> worker.log 2>&1"'
fi

exec gosu openclaw node src/server.js
