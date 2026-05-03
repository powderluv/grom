# Grom Reboot Notes

## Current State

- Project root: `~/github/grom`
- ChromiumOS checkout: `~/github/grom/cros`
- Depot tools: `~/github/grom/depot_tools`
- Active board: `grom-amd64`
- Board overlay: `~/github/grom/cros/src/private-overlays/overlay-grom-amd64-private`
- Base profile: `amd64-generic`
- Toolchain tuple: `x86_64-cros-linux-gnu`

## Implemented

- Renamed the project to Grom.
- Added the standalone `overlay-grom-amd64-private` board overlay.
- Added `chromeos-base/grom-config`, installing `/etc/grom-release`.
- Added `chromeos-base/grom-bsp`; `grom-bsp-0.0.1-r1` now installs the board
  Omaha/app ID metadata via the ChromiumOS `appid` eclass.
- Added `virtual/chromeos-bsp` for the board.
- Added Grom `chromeos-config-bsp` model YAML.
- Added `chromeos-base/grom-omarchy-config` with Omarchy-to-Portage package
  mapping metadata.
- Added `chromeos-base/grom-omarchy-meta`.
- Added `virtual/target-grom-os`.
- Overrode `virtual/target-os` with `target-os-2::grom-amd64` so image builds
  enter the Grom target path.
- Updated `PLAN.md` for Grom naming and next phases.

## Verified Before Reboot

Run from `~/github/grom/cros` with:

```bash
export PATH="$HOME/github/grom/depot_tools:$PATH"
```

Completed successfully:

```bash
cros lint src/private-overlays/overlay-grom-amd64-private
cros_sdk --working-dir=/mnt/host/source -- ./chromite/bin/setup_board --board=grom-amd64 --force
cros_sdk --working-dir=/mnt/host/source -- emerge-grom-amd64 virtual/chromeos-bsp chromeos-base/chromeos-config-bsp
cros_sdk --working-dir=/mnt/host/source -- emerge-grom-amd64 --nodeps chromeos-base/chromeos-config
cros_sdk --working-dir=/mnt/host/source -- emerge-grom-amd64 chromeos-base/grom-omarchy-meta
cros_sdk --working-dir=/mnt/host/source -- emerge-grom-amd64 --nodeps virtual/target-grom-os virtual/target-os
```

The generated config reported:

```json
{"chromeos":{"configs":[{"brand-code":"ZZCR","identity":{"platform-name":"Grom"},"name":"grom-amd64"}]}}
```

The installed release file reported:

```text
NAME=Grom
ID=grom
BOARD=grom-amd64
BASE_ID=chromiumos
VERSION_ID=0.0.1
PRETTY_NAME="Grom 0.0.1 amd64"
```

## Full Build Progress

- Moved the Grom board overlay out of the upstream `src/overlays` repo and
  into the standalone private board overlay path:
  `src/private-overlays/overlay-grom-amd64-private`.
- The private overlay uses `repo-name = grom-amd64-private`, and
  `cros query boards -f 'name == "grom-amd64"'` reports it as both the private
  and top-level overlay.
- `setup_board --board=grom-amd64 --force --skip-toolchain-update` regenerated
  `/build/grom-amd64` with the private overlay in `BOARD_OVERLAY` and
  `PORTDIR_OVERLAY`.
- `emerge-grom-amd64 --nodeps virtual/target-grom-os virtual/target-os`
  completed from `::grom-amd64-private`.
- Added a board-local
  `chromeos-base/crosid-0.0.1-r292::grom-amd64-private` override so Meson tests
  run through a `platform2_test.py --strategy=sudo --user=root` wrapper. This
  cleared the host namespace failure in `/proc/self/setgroups`.
- `cros build-packages --board=grom-amd64 --jobs=16 --skip-setup-board --no-withtest --no-withautotest --no-withfactory`
  completed successfully.
- The first `cros build-image` run reached DLC generation and failed because
  `/build/grom-amd64/etc/lsb-release` had no `CHROMEOS_RELEASE_APPID`.
- Fixed that by adding the BSP app ID:
  `{D919A2A2-D781-4472-A42E-1DECBF32859D}` with `DEVICETYPE=REFERENCE`.
- `cros build-image --board=grom-amd64 --jobs=16 --no-enable-rootfs-verification --replace dev`
  completed successfully.

Current bootable dev image:

```text
~/github/grom/cros/src/build/images/grom-amd64/latest/chromiumos_image.bin
~/github/grom/cros/src/build/images/grom-amd64/R149-16665.0.0-d2026_05_03_022827-a1/chromiumos_image.bin
```

The image is about 11 GiB. ChromiumOS reported the VM command:

```bash
cros vm --start --image-path=src/build/images/grom-amd64/R149-16665.0.0-d2026_05_03_022827-a1/chromiumos_image.bin --board=grom-amd64
```

`cros vm --start` booted to the ChromiumOS OOBE screen over VNC, but kept
waiting for SSH readiness. A direct QEMU helper was added so the VM can stay
running independently with a copy-on-write overlay:

```bash
GROM_VM_VNC_BIND=192.168.1.108 GROM_VM_VNC_PASSWORD=gromtest ~/github/grom/tools/run-grom-vm.sh
~/github/grom/tools/stop-grom-vm.sh
```

Current VM launch state:

```text
PID: 775149
VNC: 192.168.1.108:5900
VNC password: gromtest
SSH forward: 127.0.0.1:9222
Overlay disk: ~/github/grom/cros/out/tmp/grom-vm/grom.qcow2
Latest screenshot: /tmp/grom-qemu-vnc.png
```

`192.168.1.108:5900` was verified locally with an RFB/VNC banner response.
The VNC server is currently advertising password authentication.

## Useful Resume Commands

```bash
cd ~/github/grom/cros
export PATH="$HOME/github/grom/depot_tools:$PATH"
git -C src/private-overlays/overlay-grom-amd64-private status -sb
./chromite/bin/cros query overlays --board=grom-amd64 -o '{name} {path} {is_private}'
cros_sdk --working-dir=/mnt/host/source -- qlist-grom-amd64 -ICv chromeos-base/chromeos-config chromeos-base/chromeos-config-bsp chromeos-base/grom-bsp chromeos-base/grom-config chromeos-base/grom-omarchy-config chromeos-base/grom-omarchy-meta virtual/chromeos-bsp virtual/target-grom-os virtual/target-os
```

Next likely implementation step: boot the generated dev image in a VM, then
choose the first real Omarchy package slice to port, starting with packages
already present in ChromiumOS Portage such as `app-misc/jq`, `app-misc/tmux`,
and `gui-apps/wl-clipboard`, then add missing Wayland/Hyprland packages as
ebuilds.
