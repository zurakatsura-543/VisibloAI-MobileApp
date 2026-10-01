"""Check exported iOS executables for simulator contamination and OS mismatches."""
import pathlib
import plistlib
import re
import subprocess
import sys
import tempfile
import zipfile


def version(value):
    return tuple((list(map(int, value.split('.'))) + [0] * 3)[:3])


with tempfile.TemporaryDirectory() as directory:
    with zipfile.ZipFile(sys.argv[1]) as archive:
        archive.extractall(directory)
    apps = list(pathlib.Path(directory).glob('Payload/*.app'))
    if len(apps) != 1:
        raise SystemExit('Expected exactly one app in the IPA Payload.')
    count = 0
    for plist in apps[0].rglob('Info.plist'):
        info = plistlib.loads(plist.read_bytes())
        executable = info.get('CFBundleExecutable')
        if not executable:
            continue
        binary = plist.parent / executable
        output = subprocess.check_output(
            ['xcrun', 'vtool', '-show-build', str(binary)], text=True
        )
        platforms = re.findall(r'platform (\S+)', output)
        minimums = re.findall(r'minos ([\d.]+)', output)
        # Older device frameworks use the legacy iPhoneOS load command.
        if not platforms and 'LC_VERSION_MIN_IPHONEOS' in output:
            platforms = ['IOS']
            minimums = re.findall(r'^\s+version ([\d.]+)', output, re.MULTILINE)
        if not platforms or any(p != 'IOS' for p in platforms):
            raise SystemExit(f'Invalid platform in {binary.name}: {platforms}')
        declared = info.get('MinimumOSVersion')
        if not minimums or not declared or any(
            version(m) > version(declared) for m in minimums
        ):
            raise SystemExit(f'OS version mismatch in {binary.name}: {minimums}, plist={declared}')
        count += 1
    subprocess.run(
        ['codesign', '--verify', '--deep', '--strict', str(apps[0])], check=True
    )
    print(f'PASS: {count} iOS executables, minimum OS metadata, and app signatures.')
