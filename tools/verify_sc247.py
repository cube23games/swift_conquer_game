#!/usr/bin/env python3
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / 'swiftconquer_master'))
from verify_stage import main

if __name__ == '__main__':
    sys.argv.insert(1, 'SC-247')
    raise SystemExit(main())
