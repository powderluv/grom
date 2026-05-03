#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CROS="${ROOT}/cros"
BOARD="grom-amd64"
IMAGE="${1:-${CROS}/src/build/images/${BOARD}/latest/chromiumos_image.bin}"
VM_DIR="${GROM_VM_DIR:-${CROS}/out/tmp/grom-vm}"
VNC_BIND="${GROM_VM_VNC_BIND:-127.0.0.1}"
VNC_PORT="${GROM_VM_VNC_PORT:-5900}"
VNC_PASSWORD="${GROM_VM_VNC_PASSWORD:-}"
SSH_PORT="${GROM_VM_SSH_PORT:-9222}"

if [[ ! -f "${IMAGE}" ]]; then
	echo "Image not found: ${IMAGE}" >&2
	exit 1
fi

if [[ -f "${VM_DIR}/qemu.pid" ]] && kill -0 "$(cat "${VM_DIR}/qemu.pid")" 2>/dev/null; then
	echo "Grom VM is already running with pid $(cat "${VM_DIR}/qemu.pid")."
	echo "VNC: ${VNC_BIND}:${VNC_PORT}"
	echo "SSH forward: 127.0.0.1:${SSH_PORT}"
	exit 0
fi

if [[ ${#VNC_PASSWORD} -gt 8 ]]; then
	echo "GROM_VM_VNC_PASSWORD must be 8 characters or fewer for QEMU VNC auth." >&2
	exit 1
fi

QEMU_BIN="$(find "${CROS}/.cache/cipd/packages/chromiumos/infra/tools/qemu" \
	-path "*/bin/qemu-system-x86_64" -type f | head -n 1)"
QEMU_IMG="$(find "${CROS}/.cache/cipd/packages/chromiumos/infra/tools/qemu" \
	-path "*/bin/qemu-img" -type f | head -n 1)"

if [[ -z "${QEMU_BIN}" || -z "${QEMU_IMG}" ]]; then
	echo "ChromiumOS CIPD QEMU tools were not found under ${CROS}/.cache." >&2
	exit 1
fi

rm -rf "${VM_DIR}"
mkdir -p "${VM_DIR}"

"${QEMU_IMG}" create -f qcow2 -F raw -b "${IMAGE}" "${VM_DIR}/grom.qcow2"

VNC_ARG="${VNC_BIND}:$((VNC_PORT - 5900))"
if [[ -n "${VNC_PASSWORD}" ]]; then
	VNC_ARG="${VNC_ARG},password=on"
fi

"${QEMU_BIN}" \
	-m 8G \
	-smp 8 \
	-daemonize \
	-pidfile "${VM_DIR}/qemu.pid" \
	-serial "file:${VM_DIR}/serial.log" \
	-monitor "unix:${VM_DIR}/monitor.sock,server,nowait" \
	-cpu Opteron_G4,-invpcid,-tsc-deadline,check,vmx=on,svm=on \
	-usb \
	-device nec-usb-xhci \
	-device usb-tablet \
	-device usb-kbd \
	-device virtio-net,netdev=eth0 \
	-device virtio-scsi-pci,id=scsi \
	-device virtio-rng \
	-device scsi-hd,drive=hd,rotation_rate=1 \
	-drive "if=none,id=hd,file=${VM_DIR}/grom.qcow2,cache=unsafe,format=qcow2" \
	-netdev "user,id=eth0,net=10.0.2.0/27,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
	-enable-kvm \
	-vga virtio \
	-vnc "${VNC_ARG}"

if [[ -n "${VNC_PASSWORD}" ]]; then
	for _ in {1..20}; do
		[[ -S "${VM_DIR}/monitor.sock" ]] && break
		sleep 0.1
	done
	printf 'set_password vnc %s\n' "${VNC_PASSWORD}" | nc -N -U "${VM_DIR}/monitor.sock" >/dev/null
fi

echo "Grom VM started with pid $(cat "${VM_DIR}/qemu.pid")."
echo "VNC: ${VNC_BIND}:${VNC_PORT}"
if [[ -n "${VNC_PASSWORD}" ]]; then
	echo "VNC password: ${VNC_PASSWORD}"
fi
echo "SSH forward: 127.0.0.1:${SSH_PORT}"
echo "Overlay disk: ${VM_DIR}/grom.qcow2"
