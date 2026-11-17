# SPDX-FileCopyrightText: 2026 Riki Nakamura
#
# SPDX-License-Identifier: MIT OR Apache-2.0

# Merge the managed entries ($next) into the settings file, replacing the entries this merge added last time ($prev).
# Output the merged settings and the entries this merge added, which become $prev of the next merge.

def swap(current; owned; next):
  ((current // []) - (owned // [])) as $kept
  | ((next // []) - $kept) as $added
  | { value: ($kept + $added), added: $added };

def put(path; value):
  if value == [] then delpaths([path]) else setpath(path; value) end;

def prune(key):
  if (.[key] // {}) == {} then del(.[key]) else . end;

($prev[0] // {}) as $p
| ($next[0] // {}) as $n
| reduce ("allow", "ask", "deny") as $key ({ settings: ., added: {} };
    swap(.settings.permissions[$key]; $p.permissions[$key]; $n.permissions[$key]) as $r
    | .settings |= put(["permissions", $key]; $r.value)
    | .added |= put(["permissions", $key]; $r.added))
| reduce ((($p.hooks // {}) + ($n.hooks // {})) | keys[]) as $event (.;
    swap(.settings.hooks[$event]; $p.hooks[$event]; $n.hooks[$event]) as $r
    | .settings |= put(["hooks", $event]; $r.value)
    | .added |= put(["hooks", $event]; $r.added))
| .settings |= (prune("permissions") | prune("hooks"))
| .added |= (prune("permissions") | prune("hooks"))
