"""Prove persisted preferences initialize two real owned app launches."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'Tools/owned_app.swift'


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', required=True, type=Path)
    args = parser.parse_args()
    bundle = args.bundle.resolve()
    executable = bundle / 'Contents/MacOS/CommandKitDemo'
    if not executable.is_file():
        parser.error('Built CommandKitDemo executable is missing')
    suite = 'CommandKitTests.Verify.Relaunch.' + str(uuid.uuid4())
    owned_pid = None
    results = []
    with tempfile.TemporaryDirectory(prefix='commandkit-relaunch-') as temporary:
        task = Path(temporary)
        try:
            for number in range(2):
                pid_path = task / f'pid-{number}'
                health_path = task / f'health-{number}.json'
                launch = ['xcrun', 'swift', str(HELPER), 'launch', str(bundle), str(pid_path),
                          '--test-suite', suite, '--verify-output', str(health_path)]
                if number == 0:
                    launch += ['--test-demo-data-off', '--test-theme', 'dark', '--test-menu-presentation', 'compact']
                subprocess.run(launch, check=True)
                owned_pid = int(pid_path.read_text())
                for _ in range(75):
                    if health_path.exists():
                        break
                    time.sleep(0.2)
                health = json.loads(health_path.read_text())
                assert health['pid'] == owned_pid and Path(health['bundlePath']).resolve() == bundle, health
                assert health['hasWindow'] and health['actionSucceeded'] and health['clipboardReadbackMatches'], health
                assert not health['demoDataEnabled'] and health['sampleCount'] == health['inboxCount'] == 0, health
                assert health['theme'] == 'dark' and health['menuPresentation'] == 'compact', health
                results.append(health)
                # Preserve only our suite for the second launch; no production defaults.
                subprocess.run(['xcrun', 'swift', str(HELPER), 'stop', str(owned_pid), str(bundle), str(executable)], check=True)
                owned_pid = None
            print(json.dumps({'status': 'pass', 'first': results[0], 'relaunched': results[1]}, sort_keys=True))
        finally:
            cleanup_pid = owned_pid or (results[-1]['pid'] if results else 0)
            subprocess.run(['xcrun', 'swift', str(HELPER), 'stop', str(cleanup_pid),
                            str(bundle), str(executable), suite], check=True)


if __name__ == '__main__':
    main()
