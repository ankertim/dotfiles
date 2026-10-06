#!/usr/bin/env bash
# 依 `herdr agent list` 的順序，替每個 agent pane 回報 $idx token（1、2、3…）
INTERVAL=${INTERVAL:-2}
TTL_MS=$((INTERVAL * 5000))   # 腳本停掉後，編號會在 TTL 後自動消失

while true; do
  n=0
  while read -r pane_id; do
    n=$((n + 1))
    herdr pane report-metadata "$pane_id" --source idx --token "idx=$n" --ttl-ms "$TTL_MS" >/dev/null 2>&1
  done < <(herdr agent list 2>/dev/null | jq -r '.result.agents[].pane_id')
  sleep "$INTERVAL"
done
