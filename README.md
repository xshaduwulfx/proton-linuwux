<p align="center">
  <img src="assets/banner.svg" alt="Proton-LinUwUx" width="900">
</p>

<p align="center">
  Automated Proton-GE and Proton-CachyOS builds patched with <strong>LinUwUx.patch</strong>.
</p>

<p align="center">
  <a href="https://github.com/xshaduwulfx/proton-linuwux/releases">
    <img src="https://img.shields.io/github/v/release/xshaduwulfx/proton-linuwux?label=Latest%20Version" alt="Latest Version">
  </a>
  <a href="https://github.com/xshaduwulfx/proton-linuwux/actions/workflows/build-ge.yml">
    <img src="https://github.com/xshaduwulfx/proton-linuwux/actions/workflows/build-ge.yml/badge.svg" alt="Proton-GE Build">
  </a>
  <a href="https://github.com/xshaduwulfx/proton-linuwux/actions/workflows/build-cachyos.yml">
    <img src="https://github.com/xshaduwulfx/proton-linuwux/actions/workflows/build-cachyos.yml/badge.svg" alt="Proton-CachyOS Build">
  </a>
  <a href="https://github.com/xshaduwulfx/proton-linuwux/stargazers">
    <img src="https://img.shields.io/github/stars/xshaduwulfx/proton-linuwux?style=flat" alt="GitHub Stars">
  </a>
</p>

<p align="center">
  <a href="https://github.com/xshaduwulfx/proton-linuwux/releases">Downloads</a>
  ·
  <a href="#features">Features</a>
  ·
  <a href="#installation">Installation</a>
  ·
  <a href="#faq">FAQ</a>
</p>

---

## About

**Proton-LinUwUx** provides automated x86_64 builds of Proton-GE and Proton-CachyOS patched with `LinUwUx.patch`.

`LinUwUx.patch` is developed and maintained by **LinUwUx**.  
This project only automates the build and distribution of Proton-GE and Proton-CachyOS with the original patch applied.

The patch originates from the relevant discussion on [cs.rin.ru](https://cs.rin.ru/forum/viewtopic.php?f=10&t=159989).

> [!IMPORTANT]
> These builds contain no additional performance tweaks or unrelated changes.  
> The only project-specific modification is the application of the original `LinUwUx.patch` developed by **LinUwUx**.

### Experimental modular hooks

The sources under `scripts/linuwux/` on the `experimental` branch are derived
from [brcly/proton-LinUwUx-patch](https://github.com/brcly/proton-LinUwUx-patch)
(AGPL-3.0), based on the original LinUwUx work. See `scripts/linuwux/NOTICE`.

## Features

- Automatically tracks new upstream Proton-GE and Proton-CachyOS releases.
- Builds and publishes patched releases through GitHub Actions.
- Provides ready-to-use x86_64 archives.
- Keeps Proton-GE and Proton-CachyOS as separate release variants.
- Allows manual workflow runs when a rebuild is required.

## Available builds

| Build | Upstream project | Architecture | Description |
|---|---|---:|---|
| **Proton-GE LinUwUx** | [GloriousEggroll/proton-ge-custom](https://github.com/GloriousEggroll/proton-ge-custom) | x86_64 | Latest supported Proton-GE release patched with `LinUwUx.patch`. |
| **Proton-CachyOS LinUwUx** | [CachyOS/proton-cachyos](https://github.com/CachyOS/proton-cachyos) | x86_64 | Latest supported Proton-CachyOS release patched with `LinUwUx.patch`. |

## Downloads

Ready-to-use builds are available from the project’s:

<p align="center">
  <strong>
    <a href="https://github.com/xshaduwulfx/proton-linuwux/releases">GitHub Releases</a>
  </strong>
</p>

Each release archive contains a complete compatibility-tool directory that can be extracted into a supported Steam compatibility-tools location.

## Installation

### Steam

1. Download the desired archive from [GitHub Releases](https://github.com/xshaduwulfx/proton-linuwux/releases).
2. Extract it into one of the following directories:

   ```text
   ~/.steam/root/compatibilitytools.d/
   ~/.local/share/Steam/compatibilitytools.d/
   ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/compatibilitytools.d/
   ```

3. Create the selected directory if it does not already exist.
4. Restart Steam.
5. Right-click the game and open **Properties → Compatibility**.
6. Enable **Force the use of a specific Steam Play compatibility tool**.
7. Select the installed Proton-LinUwUx build.

### Faugus Launcher

1. Extract the build into one of the Steam compatibility-tools directories listed above.
2. When using the Flatpak version of Faugus Launcher, open **Flatseal**.
3. Select Faugus Launcher and add the extraction path under **Filesystems → Other files**.
4. Open:

   ```text
   ~/.var/app/io.github.Faugus.faugus-launcher/data/faugus-launcher/games.json
   ```

5. Find the relevant game entry and set its `"runner"` value to the absolute path of the extracted Proton directory.

> [!NOTE]
> The runner path may need to be set again after adding a game or changing its launch options.

## FAQ

### How does the Hypervisor (HV) bypass work? What are the requirements? What additional components are required besides these patched Proton builds?

**These patched Proton builds are a required part of the setup, but they are not the complete solution.**

This repository only builds and distributes the patched Proton variants required for the HV bypass to work properly. The HV bypass itself, its configuration, additional requirements, and the overall setup are **outside the scope of this project**.

If you're looking for information about the complete setup, requirements, compatibility or troubleshooting, please refer to the dedicated **[cs.rin.ru discussion thread](https://cs.rin.ru/forum/viewtopic.php?f=10&t=159989)**.

For questions regarding the HV bypass itself or its setup, please use the discussion thread above rather than opening an issue in this repository.

### What is the difference between Proton-CachyOS and Proton-GE?

Both variants receive the same project-specific patch, but they are based on different upstream Proton projects.

Proton-GE and Proton-CachyOS may contain different Wine patches, components, defaults and compatibility changes. Results can therefore vary between games.

### Do these builds work on immutable distributions?

Yes. This includes systems such as Steam Deck, Fedora Silverblue and Bazzite.

Install the compatibility tool inside your home directory, for example:

```text
~/.steam/root/compatibilitytools.d/
~/.local/share/Steam/compatibilitytools.d/
~/.var/app/com.valvesoftware.Steam/.local/share/Steam/compatibilitytools.d/
```

Do not attempt to install it into a read-only system directory such as `/usr/share/steam`.

### Does the hypervisor bypass work on ARM devices?

No. Translators such as FEX-Emu do not currently provide all the required behavior, including `cpuid_fault` support, and user-mode emulation cannot reproduce every property checked by some protection systems.

These builds target **x86_64 Linux systems only**.

### Does it work with every Denuvo-protected game?

No compatibility guarantee can be made.

The patch targets hypervisor-related checks, but results depend on the game, its protection version and any game-specific requirements. Consult the original [cs.rin.ru discussion](https://cs.rin.ru/forum/viewtopic.php?f=10&t=159989) and the relevant game thread for additional information.

### Is there a risk of being banned?

Use these builds at your own risk.

Modified compatibility tools or attempts to bypass anti-tamper systems may violate the terms of service of a game, platform or online service. Avoid using modified builds in competitive or anti-cheat-protected multiplayer environments.

### How often are new releases checked?

The GitHub Actions workflows check the upstream Proton-GE and Proton-CachyOS projects every hour.

When a new upstream release is detected and no corresponding Proton-LinUwUx release exists, the appropriate build workflow starts automatically.

## Disclaimer

This repository is an independent community project and is not affiliated with Valve, CodeWeavers, GloriousEggroll, CachyOS or any game publisher.

All trademarks and project names belong to their respective owners.

## Credits

- **LinUwUx** (original patch author)
- **[brcly/proton-LinUwUx-patch](https://github.com/brcly/proton-LinUwUx-patch)** (modular hooks under `scripts/linuwux/` on experimental)
- **Kurt Himebauch** (legacy Reflex hooks)
- **DenuvOwO Team**
- **GloriousEggroll**
- **CachyOS Team**
- **Valve** and **CodeWeavers** for Proton and Wine development
