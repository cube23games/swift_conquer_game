from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os
import subprocess
import time


@dataclass(frozen=True)
class CommandResult:
    name: str
    command: list[str]
    exit_code: int
    seconds: float
    output: str

    @property
    def passed(self) -> bool:
        return self.exit_code == 0


def run_command(
    name: str,
    command: list[str],
    *,
    cwd: Path,
    timeout: int = 1800,
) -> CommandResult:
    started = time.monotonic()
    env = {**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'}
    try:
        completed = subprocess.run(
            command,
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=env,
            timeout=timeout,
        )
        code = completed.returncode
        output = completed.stdout or ''
    except subprocess.TimeoutExpired as exc:
        code = 124
        output = (exc.stdout or '') + '\nTIMEOUT\n'
    return CommandResult(
        name=name,
        command=command,
        exit_code=code,
        seconds=round(time.monotonic() - started, 3),
        output=output,
    )
