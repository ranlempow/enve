#!/bin/sh

if [ -z "$ENVE_HOME" ]; then
    exit 1
fi

# APPNAME=${2:-$(basename "${1}" '.sh')};
APPNAME=$1
LINE=$2
# DIR="${APPNAME}.app/Contents/MacOS"

if [ -a "${APPNAME}.app" ]; then
    echo "${PWD}/${APPNAME}.app already exists :("
    exit 1
fi

mkdir -p "${APPNAME}.app/Contents/MacOS";
{
    echo "#!/bin/sh"
    echo "'automatic create by enve script'"
    echo ""
    echo "$LINE"
} > "${APPNAME}.app/Contents/MacOS/${APPNAME}"
chmod +x "${APPNAME}.app/Contents/MacOS/${APPNAME}"

mkdir "${APPNAME}.app/Contents/Resources"
cp "$ENVE_HOME/../share/enve/app-store-icon-8507.icns" "${APPNAME}.app/Contents/Resources/$APPNAME.icns"
chmod 644 "${APPNAME}.app/Contents/Resources/$APPNAME.icns"

cat > "${APPNAME}.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSMinimumSystemVersion</key>
    <string>10.9.0</string>
    <key>CFBundleExecutable</key>
    <string>$APPNAME</string>
    <key>CFBundleGetInfoString</key>
    <string>$APPNAME By ENVE</string>
    <key>CFBundleIconFile</key>
    <string>$APPNAME.icns</string>
    <key>CFBundleIdentifier</key>
    <string>org.enveapp.$APPNAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APPNAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.81a</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>2.81a 2019-12-04</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

touch "${APPNAME}.app"
# echo "${PWD}/$APPNAME.app";
