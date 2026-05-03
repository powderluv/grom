#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_DIR="${GROM_VM_DIR:-${ROOT}/cros/out/tmp/grom-vm}"
PID_FILE="${VM_DIR}/qemu.pid"

if [[ ! -f "${PID_FILE}" ]]; then
	echo "No Grom VM pid file found at ${PID_FILE}."
	exit 0
fi

PID="$(cat "${PID_FILE}")"
if ! kill -0 "${PID}" 2>/dev/null; then
	echo "Grom VM pid ${PID} is not running."
	exit 0
fi

kill "${PID}"
echo "Stopped Grom VM pid ${PID}."
