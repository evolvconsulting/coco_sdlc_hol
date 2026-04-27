#!/usr/bin/env python3
"""
hol_provision.py — backwards-compatible shim.

The provisioning logic now lives in provision_attendees.py.
This file is kept so any existing bookmarks/docs still work.

Preferred usage (from repo root):
    uv run python3 scripts/provision_attendees.py [--users N] [--workers N]
    uv run python3 scripts/hol_setup.py --phase provision
"""
from provision_attendees import main

if __name__ == "__main__":
    main()
