# Grom

Grom is a ChromiumOS-derived distribution experiment. It keeps the
ChromiumOS/Gentoo Portage base and layers Omarchy-oriented package and
configuration metadata above it.

## Workspace

The full ChromiumOS checkout lives at `cros/` and depot tools live at
`depot_tools/`. Both directories are intentionally left outside this Git repo.

The active board overlay is in:

```text
cros/src/overlays/overlay-grom-amd64
```

## Build

From `~/github/grom/cros`:

```bash
export PATH="$HOME/github/grom/depot_tools:$PATH"

cros_sdk --working-dir=/mnt/host/source -- \
  cros build-packages --board=grom-amd64 --jobs=16 --skip-setup-board \
  --no-withtest --no-withautotest --no-withfactory

cros_sdk --working-dir=/mnt/host/source -- \
  cros build-image --board=grom-amd64 --jobs=16 \
  --no-enable-rootfs-verification --replace dev
```

The current developer image path is:

```text
cros/src/build/images/grom-amd64/latest/chromiumos_image.bin
```

## VM

Start a VM with VNC exposed to the local network:

```bash
GROM_VM_VNC_BIND=192.168.1.108 GROM_VM_VNC_PASSWORD=gromtest \
  ./tools/run-grom-vm.sh
```

Stop it with:

```bash
./tools/stop-grom-vm.sh
```
