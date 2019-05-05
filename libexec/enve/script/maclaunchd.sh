#!/usr/bin/env bash

if [ -z "${ENVE_HOME:-}" ]; then
    echo "fatal: ENVE_HOME not set." >&2
    exit 1
fi

# shellcheck disable=2034
ENVE_PROGRAM=enve/maclaunchd

# shellcheck source=libexec/enve/base
. "$ENVE_HOME/enve/base"
settrace


service_name="envsrv"
service_args=~/envsrv.sh
service_envs="SP_ENV SPvalue"
service_label="tw.org.enve.$service_name"

domain_target=system
domain_target=gui/$(id -u)

dest="/Library/LaunchDaemons/$service_label.plist"
dest="$HOME/Library/LaunchAgents/$service_label.plist"

var=/var
var=~/.local


is_loaded() {
    # TODO: find replacement for deprecated "list"
    launchctl list | grep "$service_label"
}

service_kill() {
    _info "Sending SIGTERM ..."
    launchctl kill SIGTERM "${domain_target}/${service_label}"
    while is_loaded; do
        sleep 5
        is_loaded || break
        _info "Sending SIGKILL ..."
        launchctl kill SIGKILL "${domain_target}/${service_label}"
    done
    _info "Successfully stopped ${service_name} via ${service_label}"
}

service_start() {
    tmpplist="$(mkstemp ${TMPDIR:-/tmp}/$service_label.plist.XXXXXX)"
    generate_plist > "$tmpplist"
    rm -rf "$dest"
    cp "$tmpplist" "$dest"
    chmod 644 "$dest"
    launchctl bootstrap "$domain_target" "$dest"
    launchctl enable "$domain_target/$service_label"
    _info "Successfully started ${service_name} (label: ${service_label})"
}

service_stop() {
    _info "Stopping ${service_name}... (might take a while)"
    set +e
    launchctl bootout "$domain_target/$service_label"
    while [ "$?" = 9216 ]; do
        sleep 5
        launchctl bootout "$domain_target/$service_label"
    done
    set -e
    if ! is_loaded; then
        _info "Successfully stopped ${service_name} (label: ${service_label})"
    else
        service_kill
    fi
    rm -rf "$dest"
}

generate_plist() {
    mkdir -p "$var/log/$service_name"

    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${service_label}</string>
  <key>ProgramArguments</key>
  <array>
EOF

    for arg in $service_args; do
        printf '    <string>%s</string>' "$arg"
    done

    cat <<EOF
  </array>
  <key>EnvironmentVariables</key>
  <dict>
EOF
    if [ -n "$service_envs" ]; then
        while read -r key value; do
            printf '    <key>%s</key>\n    <string>%s</string>' "$key" "$value"
        done <<EOF
$service_envs
EOF
    fi

    cat <<EOF
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$var/log/$service_name/$service_name.out.log</string>
  <key>StandardErrorPath</key>
  <string>$var/log/$service_name/$service_name.err.log</string>
</dict>
</plist>
EOF

}

"$1"
