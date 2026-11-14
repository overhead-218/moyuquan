# -*- coding: utf-8 -*-
"""逐条执行 sql/part8.sql —— tcb db execute 只接受单条 --sql，
这里把建桶 + 5 条策略拆开按序执行，并校验结果。

幂等：part8.sql 本身就是幂等脚本，重复执行安全。
"""
import subprocess
import sys

ENV = 'moyuquan-d5g0pvpcw55f8a62e'

STATEMENTS = [
    # 1. 建桶（public=true 才能生成稳定 CDN 直链）
    ("""INSERT INTO storage.buckets
         (id, name, public, file_size_limit, allowed_mime_types)
       VALUES
         ('spot-photos', 'spot-photos', true, 10485760,
          ARRAY['image/jpeg','image/png','image/webp']),
         ('post-photos', 'post-photos', true, 10485760,
          ARRAY['image/jpeg','image/png','image/webp'])
       ON CONFLICT (id) DO UPDATE
         SET public             = EXCLUDED.public,
             file_size_limit    = EXCLUDED.file_size_limit,
             allowed_mime_types = EXCLUDED.allowed_mime_types,
             updated_at         = now()""", '建桶 spot-photos / post-photos'),

    # 2. 桶元数据任何人可读
    ("DROP POLICY IF EXISTS buckets_select_all ON storage.buckets", '清理旧桶读策略'),
    ("""CREATE POLICY buckets_select_all ON storage.buckets
         FOR SELECT TO anon, authenticated USING (true)""", '桶元数据可读'),

    # 3. 照片公开读
    ("DROP POLICY IF EXISTS spot_photos_public_read ON storage.objects", '清理旧照片读策略'),
    ("""CREATE POLICY spot_photos_public_read ON storage.objects
         FOR SELECT TO anon, authenticated
         USING (bucket_id IN ('spot-photos','post-photos'))""", '照片公开可读'),

    # 4. 登录用户可上传（限本人目录）
    ("DROP POLICY IF EXISTS spot_photos_authenticated_upload ON storage.objects", '清理旧上传策略'),
    ("""CREATE POLICY spot_photos_authenticated_upload ON storage.objects
         FOR INSERT TO authenticated
         WITH CHECK (
           bucket_id IN ('spot-photos','post-photos')
           AND (storage.foldername(name))[1] = auth.uid()
         )""", '登录用户上传（限本人目录）'),

    # 5. 上传方可覆盖自己目录
    ("DROP POLICY IF EXISTS spot_photos_owner_update ON storage.objects", '清理旧更新策略'),
    ("""CREATE POLICY spot_photos_owner_update ON storage.objects
         FOR UPDATE TO authenticated
         USING (
           bucket_id IN ('spot-photos','post-photos')
           AND (storage.foldername(name))[1] = auth.uid()
         )
         WITH CHECK (
           bucket_id IN ('spot-photos','post-photos')
           AND (storage.foldername(name))[1] = auth.uid()
         )""", '上传方覆盖本人照片'),

    # 6. 上传方可删自己目录
    ("DROP POLICY IF EXISTS spot_photos_owner_delete ON storage.objects", '清理旧删除策略'),
    ("""CREATE POLICY spot_photos_owner_delete ON storage.objects
         FOR DELETE TO authenticated
         USING (
           bucket_id IN ('spot-photos','post-photos')
           AND (storage.foldername(name))[1] = auth.uid()
         )""", '上传方删除本人照片'),
]


def run(sql, role=None):
    cmd = ['tcb.cmd', 'db', 'execute', '-e', ENV]
    if role:
        cmd += ['--role', role]
    cmd += ['--sql', sql]
    p = subprocess.run(cmd, capture_output=True, text=True,
                       shell=True, encoding='utf-8', errors='replace')
    return p.returncode, (p.stdout or '') + (p.stderr or '')


def main():
    ok = fail = 0
    for sql, label in STATEMENTS:
        code, out = run(sql)
        if code != 0 or 'error' in out.lower():
            fail += 1
            print(f'✗ {label}\n{out.strip()[:400]}\n')
        else:
            ok += 1
            print(f'✓ {label}')

    print(f'\n成功 {ok} / 失败 {fail}')
    if fail:
        sys.exit(1)

    # 校验
    print('\n=== 校验：bucket 列表 ===')
    run("SELECT id, public, file_size_limit, allowed_mime_types FROM storage.buckets ORDER BY id")
    code, out = run("SELECT id, public, file_size_limit FROM storage.buckets ORDER BY id")
    print(out[out.find('┌'):] if '┌' in out else out)

    print('\n=== 校验：RLS 策略列表 ===')
    code, out = run("SELECT tablename, policyname, cmd, roles FROM pg_policies WHERE schemaname='storage' ORDER BY tablename, policyname")
    print(out[out.find('┌'):] if '┌' in out else out)


if __name__ == '__main__':
    main()
