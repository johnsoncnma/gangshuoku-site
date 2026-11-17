#!/bin/bash
# 每 10 分钟从 GitHub 拉取最新的页面和课程数据，校验通过后才替换
set -e
BASE="https://raw.githubusercontent.com/johnsoncnma/gangshuoku-site/main/public"
PUB=/opt/hkms/public
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
curl -fsSL --max-time 60 "$BASE/data.json" -o "$T/data.json"
curl -fsSL --max-time 60 "$BASE/index.html" -o "$T/index.html"
python3 - "$T" <<'PY'
import json,sys,os
t=sys.argv[1]
d=json.load(open(t+"/data.json",encoding="utf-8"))
assert len(d["programmes"])>=500 and len(d["schools"])>=10
h=open(t+"/index.html",encoding="utf-8").read()
assert len(h)>50000 and "香港硕士申请信息库" in h and "/api/lead" in h and h.rstrip().endswith("</html>")
PY
for f in data.json index.html; do
  if ! cmp -s "$T/$f" "$PUB/$f"; then
    install -m 644 "$T/$f" "$PUB/$f.new" && mv "$PUB/$f.new" "$PUB/$f"
    echo "$(date '+%F %T') updated $f" >> /opt/hkms/sync.log
  fi
done
