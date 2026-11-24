#!/bin/bash
# Hash every built project .olean and compare with Sutherland's two manifests:
#   project-oleans.sha256          (his original unsandboxed build)
#   sandbox-project-oleans.sha256  (his sandboxed lake rebuild)
# Same build path (/home/ubuntu/grh/src/lean) => every file should match, except possibly
# Formalism/.../RankPointCounts/LocModel.olean (known nondeterminism; must match one of the two).
set -euo pipefail
cd "$HOME/rh/work/grh/src/lean/.lake/build/lib/lean"
find . -name '*.olean' -print0 | sort -z | xargs -0 -P 8 -n 500 sha256sum > "$HOME/rh/local-project-oleans.sha256"
python3 - <<'PY'
import os
def load(p):
    return {l.split()[1]: l.split()[0] for l in open(os.path.expanduser(p))}
o = load("~/rh/local-project-oleans.sha256")
a = load("~/rh/ref/project-oleans.sha256")
b = load("~/rh/ref/sandbox-project-oleans.sha256")
diff = [k for k in o if a.get(k) != o[k]]
print(f"local oleans: {len(o)} built, {len(a)} in manifest, {len(a) - len(o)} not yet built")
print(f"identical to original build: {len(o) - len(diff)}; differing: {len(diff)}")
for k in diff:
    print(f"  {k}  in manifest: {k in a}  matches sandboxed-rebuild manifest: {b.get(k) == o[k]}")
PY
