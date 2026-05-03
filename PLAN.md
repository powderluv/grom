# Grom Build Plan

Grom is a ChromiumOS-derived distribution that keeps the ChromiumOS/Gentoo
Portage build machinery and layers an Omarchy-style user environment above the
base system.

## Current Baseline

- Source checkout: `~/github/grom/cros`
- Depot tools: `~/github/grom/depot_tools`
- Initial board: `grom-amd64`
- Board overlay: `cros/src/private-overlays/overlay-grom-amd64-private`
- Base profile: `amd64-generic`
- Toolchain tuple: `x86_64-cros-linux-gnu`
- Grom target virtual: `virtual/target-grom-os`
- Base image override: `virtual/target-os-2::grom-amd64`

## Phase 1: Board Bring-Up

- Keep the first board close to `amd64-generic` so ChromiumOS package behavior
  stays predictable.
- Provide a standalone Grom private board overlay with its own BSP virtual,
  board metadata, model YAML, and release marker.
- Validate with `setup_board`, targeted BSP emerges, and `chromeos-config`
  generation before attempting a full image build.

## Phase 2: Omarchy Layer

- Add a dedicated package set for the higher-level desktop stack instead of
  mixing that work into the board BSP. Done for the initial metadata layer.
- Package Omarchy-facing configuration as Portage packages in the Grom overlay.
  The first package is `chromeos-base/grom-omarchy-config`.
- Keep user environment policy in small packages: shell defaults, compositor
  config, app launchers, keybindings, fonts, and curated desktop tools.
- Prefer upstream ChromiumOS packages when they already provide services needed
  by the desktop layer.

## Phase 3: Image Integration

- Create a Grom target virtual that pulls in the ChromiumOS base plus the
  Omarchy layer. Done as `virtual/target-grom-os`.
- Run `build_packages --board=grom-amd64` once the target package list is
  stable.
- Build a developer image first, then reduce the package set for a smaller
  daily-driver image.

## Phase 4: Release Shape

- Add branding files, update metadata, and explicit version files.
- Decide whether Grom tracks ChromiumOS stable directly or pins to tested
  manifest snapshots.
- Add repeatable build notes and artifact naming for local images.
