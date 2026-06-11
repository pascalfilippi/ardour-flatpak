#!/bin/sh
# Sourced from /app/bin/ardour9 by the audio-flatpak yabridge patch.
# Sets up env for the optional org.freedesktop.LinuxAudio.Plugins.yabridge
# extension. Harmless if the extension is not installed — every export is
# guarded behind the YABRIDGE_DIR existence check.

YABRIDGE_DIR=/app/extensions/Plugins/yabridge

if [ -d "$YABRIDGE_DIR" ]; then
    export YABRIDGE_HOME="$YABRIDGE_DIR"
    export YABRIDGE_DEBUG_LEVEL="${YABRIDGE_DEBUG_LEVEL:-3}"

    # Resolve WINEPREFIX against the HOST home, not the sandboxed $XDG_DATA_HOME.
    # Manager (separate Flatpak) writes the prefix at
    # <host-home>/.local/share/yabridge/wineprefix; both apps must point at the
    # same path or yabridge bridges into an empty prefix and Wine errors with
    # "chdir to /home/.../.var/app/.../data/yabridge/wineprefix: No such file
    # or directory". The sandbox rewrites $HOME / $XDG_*_HOME to per-app
    # overlays under ~/.var/app/<app-id>/, while --filesystem=home exposes the
    # host path under its original name. Mirrors manager.sh's HOST_HOME logic.
    if [ -f /.flatpak-info ]; then
        HOST_HOME="${HOME%/.var/app/*}"
    else
        HOST_HOME="$HOME"
    fi
    export WINEPREFIX="${WINEPREFIX:-$HOST_HOME/.local/share/yabridge/wineprefix}"
    export WINELOADER="$YABRIDGE_DIR/bin/wine"
    export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=}"
    # Wine's FUTEX2-based fast sync. Substantially lower audio-thread latency
    # for bridged plugins than Wine's default server-side sync — the single
    # biggest perf knob for yabridge'd plugins. Stable-25.08 Wine has fsync;
    # Linux >= 5.16 supplies the kernel side. Harmless if either is missing —
    # Wine logs and falls back silently.
    export WINEFSYNC="${WINEFSYNC:-1}"

    # PATH is already extended via finish-args --env, but be defensive in case
    # ardour9 has reset PATH by the time this runs.
    case ":$PATH:" in
        *":$YABRIDGE_DIR/bin:"*) ;;
        *) export PATH="$YABRIDGE_DIR/bin:$PATH" ;;
    esac
fi
