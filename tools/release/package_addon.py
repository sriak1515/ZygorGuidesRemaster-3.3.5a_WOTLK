"""Build the complete playable addon ZIP, source patch, and handoff files.

Usage: python tools/release/package_addon.py --output-dir dist
Requires a Git checkout. Uses only the Python standard library.
"""
import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import zipfile
from xml.etree import ElementTree

BASE = 'd2aae8d0f1f3782d964e4179907b215aab484787'
ROOT = Path(__file__).resolve().parents[2]


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'dist')
    args = parser.parse_args()
    output = args.output_dir.resolve()
    addon = ROOT / 'ZygorGuidesViewerRM'
    if output.is_relative_to(addon):
        parser.error('The output directory must be outside the addon source.')
    output.mkdir(parents=True, exist_ok=True)
    toc = addon / 'ZygorGuidesViewerRM.toc'
    assert toc.is_file(), 'Missing addon TOC'
    for name in ('files.xml', 'ZygorGuidesViewerFrame.xml'):
        ElementTree.parse(addon / name)
    assert 'Parchment.lua' in (addon / 'files.xml').read_text(), 'Missing prototype load entry'

    archive = output / 'ZygorGuidesRemaster-parchment-prototype.zip'
    files = sorted(path for path in addon.rglob('*') if path.is_file())
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for path in files:
            package.write(path, path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None, 'ZIP integrity check failed'
        assert len(package.namelist()) == len(files)
        for path in files:
            name = path.relative_to(ROOT).as_posix()
            assert package.read(name) == path.read_bytes(), f'Package differs from source: {name}'

    shutil.copyfile(ROOT / 'docs/PARCHMENT_PROTOTYPE.md', output / 'INSTALL-AND-TEST.md')
    shutil.copyfile(ROOT / 'docs/PARCHMENT_FIXTURES.md', output / 'FIXTURE-TESTS.md')
    shutil.copyfile(ROOT / 'LICENSE', output / 'LICENSE')
    (output / 'vertical-parchment.patch').write_bytes(git('diff', '--binary', BASE, 'HEAD'))
    commit = git('rev-parse', 'HEAD').decode().strip()
    (output / 'BUILD.txt').write_text(
        f'Commit: {commit}\nBase: {BASE}\nBase addon version: 3.0.255\n'
        f'Target: WoW 3.3.5a / 12340\nFiles: {len(files)} (verified against source)\n'
        'Client testing: NOT RUN\n'
        'See INSTALL-AND-TEST.md for context metadata, combat limitations and required client tests.\n'
    )
    checksums = []
    for path in sorted(output.iterdir()):
        if path.is_file() and path.name != 'SHA256SUMS.txt':
            checksums.append(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name)
    (output / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n')
    print(f'Verified {archive.name}: {len(files)} files, {archive.stat().st_size:,} bytes; commit {commit}')


if __name__ == '__main__':
    main()
