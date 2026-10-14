"""Run only task-owned process fixtures; --native also builds and verifies the app."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', action='store_true')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='commandkit-script-fixture-') as temporary:
        task = Path(temporary)
        foreign_path = task / 'CommandKitDemo'
        subprocess.run(['xcrun', 'clang', '-x', 'c', '-', '-o', str(foreign_path)],
                       input=b'#include <unistd.h>\nint main(void) { sleep(180); return 0; }\n', check=True)
        foreign = subprocess.Popen([str(foreign_path), '180'])
        try:
            mock_bin = task / 'bin'
            mock_bin.mkdir()
            called = task / 'build-called'
            mock = mock_bin / 'xcodebuild'
            mock.write_text('#!/bin/bash\nprintf built > "$COMMANDKIT_FIXTURE_LOG"\nexit 42\n')
            mock.chmod(0o755)
            env = dict(os.environ, PATH=str(mock_bin) + ':' + os.environ['PATH'], COMMANDKIT_FIXTURE_LOG=str(called))
            invalid = subprocess.run([str(ROOT / 'script/build_and_run.sh'), 'invalid-mode'], env=env, capture_output=True)
            assert invalid.returncode == 2 and not called.exists(), invalid.stderr.decode()
            assert foreign.poll() is None
            extra = subprocess.run([str(ROOT / 'script/build_and_run.sh'), 'run', 'unexpected'], env=env, capture_output=True)
            assert extra.returncode == 2 and not called.exists()
            failed = subprocess.run([str(ROOT / 'script/build_and_run.sh'), '--verify'], env=env, capture_output=True)
            assert failed.returncode == 42 and called.exists(), failed.stderr.decode()
            assert foreign.poll() is None, 'Build failure terminated a foreign process'
            result = {'invalidExit': invalid.returncode, 'extraArgumentExit': extra.returncode,
                      'buildFailureExit': failed.returncode, 'foreignSurvived': True}
            if args.native:
                verified = subprocess.run([str(ROOT / 'script/build_and_run.sh'), '--verify'], capture_output=True)
                assert verified.returncode == 0, verified.stderr.decode()
                assert foreign.poll() is None, 'Verify cleanup terminated a foreign process'
                health = json.loads(verified.stdout)
                assert subprocess.run(['ps', '-p', str(health['pid'])], capture_output=True).returncode != 0
                result.update(verifyExit=verified.returncode, ownedPIDStopped=True, health=health)
            print(json.dumps(result, sort_keys=True))
        finally:
            foreign.terminate()
            foreign.wait()


if __name__ == '__main__':
    main()
