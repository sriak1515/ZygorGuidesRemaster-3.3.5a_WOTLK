"""Bundle the committed viewer and the pinned, already-played compiled v1 pilot.

No compiler implementation lives here. --content-dir is the compiler's output
WoWSoloAdventureV1Pilot directory. No installed addon/WTF/server state is accessed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[2]
COMPILER_REVISION = '65becb43d3948e4238b5a576240b394e96a5d26b'
CONTENT = 'WoWSoloAdventureV1Pilot'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--content-dir', type=Path, required=True)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    source = args.content_dir.resolve()
    output = args.output_dir.resolve()
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    manifest = json.loads((source / 'BUILD.json').read_text())
    mapping = json.loads((source.parent / 'source-map.json').read_text())
    provenance = manifest['provenance']
    assert source.name == CONTENT
    assert mapping['guide']['id'] == 'EXAMPLE-KAL-01-BALANCE-ONE' and len(mapping['narration']) == 2
    assert provenance['source_revision'] == COMPILER_REVISION and not provenance['source_worktree']
    assert provenance['target_viewer_revision'] == commit, 'Recompile against this committed viewer'
    files = {}
    for name in ('Metadata.lua', 'Guide.lua', CONTENT + '.toc', 'BUILD.json'):
        files[CONTENT + '/' + name] = (source / name).read_bytes()
        if name != 'BUILD.json':
            assert sha(files[CONTENT + '/' + name]) == manifest['artifact_sha256'][name]
    readme = (ROOT / 'docs/experiments/COMPILED_PILOT_CLIENT_TEST.md').read_bytes()
    build = dict(status='EXPERIMENTAL CLIENT TEST; NOT CLIENT VERIFIED', viewer_revision=commit,
                 compiled_interface=1, provenance=provenance,
                 native_payload_sha256=mapping['native_views'][0]['payload_sha256'],
                 source_scope='matched already-played example; no active campaign migration',
                 client_testing='NOT RUN')
    files['README-CLIENT-TEST.md'] = readme
    files['BUILD.json'] = (json.dumps(build, indent=2, sort_keys=True) + '\n').encode()
    output.mkdir(parents=True, exist_ok=True)
    archive = output / ('Zygor-compiled-v1-pilot-' + commit[:7] + '.zip')
    assert not archive.exists(), 'Refusing to overwrite a previous test build'
    expected = {}
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        def add(name, data):
            assert name not in expected
            entry = zipfile.ZipInfo(name, date_time=(2026, 11, 14, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            package.writestr(entry, data)
            expected[name] = sha(data)
        # Read only committed viewer files; untracked notes and local edits cannot
        # enter the artifact. Stream to keep the complete addon within memory bounds.
        process = subprocess.Popen(['git', 'archive', commit, 'ZygorGuidesViewerRM'], cwd=ROOT, stdout=subprocess.PIPE)
        with tarfile.open(fileobj=process.stdout, mode='r|') as tree:
            for member in tree:
                if member.isfile():
                    assert member.name.startswith('ZygorGuidesViewerRM/')
                    add(member.name, tree.extractfile(member).read())
        assert process.wait() == 0
        for name, data in sorted(files.items()):
            add(name, data)
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None and set(package.namelist()) == set(expected)
        for name, digest in expected.items():
            assert sha(package.read(name)) == digest, 'Archive byte mismatch: ' + name
    build['archive_sha256'] = sha(archive.read_bytes())
    build['verified_files'] = len(expected)
    (output / 'BUILD.json').write_text(json.dumps(build, indent=2, sort_keys=True) + '\n')
    (output / 'README-CLIENT-TEST.md').write_bytes(readme)
    (output / 'SHA256SUMS').write_text('\n'.join(sha(p.read_bytes()) + '  ' + p.name
        for p in sorted(output.iterdir()) if p.is_file() and p.name != 'SHA256SUMS') + '\n')
    print(json.dumps(dict(archive=str(archive), sha256=build['archive_sha256'],
                         files=len(expected), viewer_revision=commit, client_testing='NOT RUN')))


if __name__ == '__main__':
    main()
