"""Copy the independent public-API fixture outside the checkout; never uses @testable."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    dependency = parser.add_mutually_exclusive_group(required=True)
    dependency.add_argument('--baseline', action='store_true')
    dependency.add_argument('--released', help='Exact public SemVer tag to install')
    dependency.add_argument('--local', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.is_relative_to(ROOT) or (output.exists() and any(output.iterdir())):
        parser.error('Output must be an empty directory outside the checkout')
    identity = 'MacMenuBarCommandKit'
    if args.baseline or args.released:
        version = args.released or '0.2.0'
        if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?', version):
            parser.error('Expected a bare SemVer tag')
        declaration = '.package(url: "https://github.com/mikonyaa/MacMenuBarCommandKit.git", exact: ' + json.dumps(version) + ')'
    else:
        local = args.local.resolve()
        if not (local / 'Package.swift').is_file():
            parser.error('Local package manifest is missing')
        identity = local.name
        declaration = '.package(path: ' + json.dumps(str(local), ensure_ascii=False) + ')'
    shutil.copytree(ROOT / 'Integration/Consumer', output, dirs_exist_ok=True)
    template = (output / 'Package.swift.template').read_text()
    template = template.replace('__DEPENDENCY__', declaration)
    template = template.replace('package: "MacMenuBarCommandKit"', 'package: ' + json.dumps(identity))
    (output / 'Package.swift').write_text(template)
    print(output)


if __name__ == '__main__':
    main()
