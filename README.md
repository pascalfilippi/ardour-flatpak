About Ardour flatpak
====================

Some notes about this Flatpak, for developers / maintainer.

Experimental yabridge support
-----------------------------

This fork carries small additions on top of upstream
`flathub/org.ardour.Ardour` so the optional
`org.freedesktop.LinuxAudio.Plugins.yabridge` extension can host Windows
VST/CLAP plugins from inside the Ardour sandbox. The changes are
all-or-nothing harmless: nothing kicks in unless that extension is
installed.

Delta versus upstream:

* `finish-args`
  - `--env=PATH=/app/bin:/usr/bin:/app/extensions/Plugins/yabridge/bin` —
    lets yabridge chainloader stubs in `~/.vst3/yabridge/` resolve the
    `yabridge-host.exe` shim.
  - `--allow=devel` + `--allow=multiarch` — relax seccomp for
    `ptrace` / `clone3` (wineserver) and for classic-WoW64 32-bit
    syscalls. Without these, Wine dies with `SIGSYS` the moment a host
    loads a chainloader.

* `add-extensions`
  - `org.freedesktop.Platform.Compat.i386` at `lib/i386-linux-gnu`,
    version `25.08`. Required for `/lib/ld-linux.so.2`, which Wine's
    32-bit children need.

* `modules.ardour.post-install`
  - `install -d /app/lib/i386-linux-gnu` — pre-creates the Compat.i386
    mount point; `/app` is read-only at runtime, so bwrap can't create
    it itself.
  - Install `ardour-yabridge-env.sh` to `/app/libexec/` and `sed`-insert
    a `.` (source) line into the head of `/app/bin/ardour9`. The script
    exports `YABRIDGE_HOME`, `WINEPREFIX` (resolved against the host
    home so it lines up with the Manager Flatpak), `WINELOADER`,
    `WINEDLLOVERRIDES`, and `WINEFSYNC` when the yabridge extension is
    mounted at `/app/extensions/Plugins/yabridge/`.

Dependencies
------------

The dependencies for Ardour are non standard. We try to use what is
listed at https://nightly.ardour.org/list.php#build_deps

This is to provide the closest from upstream binary builds.

Plugins support
---------------

The package supports LV2, LADSPA, and Linux VST/VST3 plugins
built for Flatpak.

Before upgrading the runtime used, please consider that the plugins
need to be upgraded first. Provision is made for plugins to live in
branches as to be available for different runtimes.

## User installed plugins

Plugins in `~/.vst3`, `~/.vst` and `~/.lv2` may work if they are built
properly. There is no universal solution if they depend on .so that are
not available or incompatible.

There is no support for Win32 emulated VST.

Network access
--------------

Starting Ardour 7, network access is granted for the loop library.

The Media library of MIDI files is installed at build time.

Jack audio support
------------------

You need to install the package `pipewire-jack-audio-connection-kit` or
equivalent in your distro. This might mean that you have to uninstall
JACK if you had it installed.

Then, just open Ardour and it will work with the Pipewire implementation of
JACK, out of the box.

ALSA Device reservation
-----------------------

Ardour requires exclusive use of the ALSA sound device. To that effect
it supports the device reservation D-Bus interface, hence the
`--own-name=org.freedesktop.ReserveDevice1.*` permission.
