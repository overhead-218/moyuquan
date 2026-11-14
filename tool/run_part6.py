# -*- coding: utf-8 -*-
"""幂等执行 part6：给 spots 补 4 列，列名带双引号保持驼峰（与 spots 现有列一致）。"""
import subprocess, sys, os

ENV = "moyuquan-d5g0pvpcw55f8a62e"
SQLS = [
    'alter table spots add column if not exists "priceTiers" jsonb default \'[]\'::jsonb',
    'alter table spots add column if not exists "status" text default \'active\'',
    'alter table spots add column if not exists "imageCaptions" jsonb default \'{}\'::jsonb',
    'alter table spots add column if not exists "imagesVerified" boolean default false',
    'update spots set "status" = \'active\' where "status" is null or "status" = \'\'',
    'update spots set "priceTiers" = \'[]\'::jsonb where "priceTiers" is null',
    'update spots set "imageCaptions" = \'{}\'::jsonb where "imageCaptions" is null',
    'update spots set "imagesVerified" = false where "imagesVerified" is null',
    'grant select, insert, update, delete on spots to anon',
]

def run(sql):
    p = subprocess.run(["tcb.cmd", "db", "execute", "-e", ENV, "--sql", sql],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = (p.stdout or "") + (p.stderr or "")
    ok = "error" not in out.lower() and "ERROR" not in out
    print(("OK  " if ok else "FAIL"), sql[:70])
    if not ok:
        print(out[-800:])
    return ok

if __name__ == "__main__":
    allok = all([run(s) for s in SQLS])
    print("ALL OK" if allok else "HAS FAILURE")
    sys.exit(0 if allok else 1)