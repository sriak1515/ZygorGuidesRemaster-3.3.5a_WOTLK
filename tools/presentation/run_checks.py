"""Dependency-free static and simulated checks using installed Lua 5.1."""
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

repo = Path(__file__).resolve().parents[2]
addon = repo / 'ZygorGuidesViewerRM'
for path in sorted(addon.glob('*.lua')):
    subprocess.run(['lua5.1', '-e', 'assert(loadstring(io.read("*a")))'],
                   input=path.read_text(encoding='utf-8-sig'), text=True, check=True)
print('PASS static: all top-level addon Lua parses under Lua 5.1', flush=True)
xml = ET.parse(addon / 'files.xml')
scripts = [n.attrib['file'] for n in xml.iter() if n.tag.endswith('Script')]
assert scripts.index('Goal.lua') < scripts.index('CampaignHash.lua') < scripts.index('CampaignAdmission.lua') < scripts.index('CampaignData.lua') < scripts.index('CampaignDelivery.lua') < scripts.index('Presentation.lua')
assert scripts.index('Parchment.lua') < scripts.index('Presentation.lua')
assert scripts.index('QuestTracking.lua') < scripts.index('BanethilStory.lua')
assert scripts.index('Presentation.lua') < scripts.index('BanethilStory.lua') < scripts.index('PresentationUI.lua')
assert scripts.index('Presentation.lua') < scripts.index('PresentationFixture.lua') < scripts.index('PresentationUI.lua')
assert 'files.xml' in (addon / 'ZygorGuidesViewerRM.toc').read_text()
for name in ('CampaignHash.lua', 'CampaignAdmission.lua', 'CampaignData.lua', 'CampaignDelivery.lua', 'Presentation.lua', 'BanethilStory.lua', 'PresentationFixture.lua', 'PresentationUI.lua'):
    assert scripts.count(name) == 1
print('PASS static: TOC/XML presentation loading order', flush=True)
failures = []
for path in sorted((repo / 'tools').rglob('test_*.lua')):
    result = subprocess.run(['lua5.1', str(path), str(addon)], cwd=repo, text=True, capture_output=True)
    if result.returncode:
        failures.append(path)
        print('FAIL', path.relative_to(repo), result.stdout, result.stderr, flush=True)
    else:
        print('PASS simulated:', path.relative_to(repo), flush=True)
if failures:
    raise SystemExit(f'{len(failures)} test scripts failed')
print('PASS all Lua regression scripts; no WoW client verification', flush=True)
