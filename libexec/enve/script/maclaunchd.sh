#!/usr/bin/env bash

if [ -z "${ENVE_HOME:-}" ]; then
    echo "fatal: ENVE_HOME not set." >&2
    exit 1
fi
ENVE_PROGRAM=enve/maclaunchd

# shellcheck source=libexec/enve/base
. "$ENVE_HOME/enve/base"
settrace


dest = "$HOME/Library/LaunchAgents/$service_label.plist"

is_loaded() {
    # TODO: find replacement for deprecated "list"
    launchctl list | grep "$service_label"
}

service_kill() {
    launchctl kill "SIGTERM" "#{domain_target}/#{service.label}"
    while is_loaded; do
        sleep 5
        is_loaded || break
        launchctl kill SIGKILL "#{domain_target}/#{service.label}"
    done
    echo "Successfully stopped `#{service.name}` via #{service.label}"
}

service_start() {
    tmpplist="$(mkstemp ${TMPDIR:-/tmp}/$service_label.plist.XXXXXX)"
    generate_plist "xxxx" > "$tmpplist"
    rm -rf "$dest"
    cp "$tmpplist" "$dest"
    chmod 644 "$dest"
    launchctl bootstrap "gui/$(id -u)" "$dest"
    launchctl enable "gui/$(id -u)/$service_label"
    echo "Successfully #{function} `#{service.name}` (label: #{service.label})"
}

service_stop() {
    echo "Stopping ${service.name}... (might take a while)"
    launchctl bootout "gui/$(id -u)/$service_label"
    while [ "$?" == 9216 ]; do
        sleep 5
        launchctl bootout "gui/$(id -u)/$service_label"
    done 
    if ! is_loaded; then
        echo "Successfully stopped `#{service.name}` (label: #{service.label})"
    else
        service_kill
    fi
    rm -rf "$dest"
}




        quiet_system launchctl, "bootout", "#{domain_target}/#{service.label}"
        while $CHILD_STATUS.to_i == 9216
          sleep(5)
          quiet_system launchctl, "bootout", "#{domain_target}/#{service.label}"
        end
      end
      if service.dest.exist?
        unless MacOS.version >= :el_capitan
          # This syntax was deprecated in Yosemite but there's no alternative
          # command (bootout) until El Capitan.
          safe_system launchctl, "unload", "-w", service.dest.to_s
        end
        ohai "Successfully stopped `#{service.name}` (label: #{service.label})"
      elsif service.loaded?
        kill(service)
      end
      rm service.dest if service.dest.exist?
end


def launchctl_load(plist, function, service)
    if MacOS.version >= :yosemite
      unless function == "ran"
        safe_system launchctl, "enable", "#{domain_target}/#{service.label}"
      end
      safe_system launchctl, "bootstrap", domain_target, plist
    else
      # This syntax was deprecated in Yosemite
      safe_system launchctl, "load", "-w", plist
    end

    ohai("Successfully #{function} `#{service.name}` (label: #{service.label})")
end