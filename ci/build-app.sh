#!/bin/bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$R/out"
DD="$R/build/DerivedData"
mkdir -p "$OUT"
mkdir -p "$R/app/Madeira/x86_64-vcruntime"

bash "$R/build/stage-licenses.sh" >/dev/null 2>&1 || true

set +e
xcodebuild -project "$R/app/Madeira.xcodeproj" -scheme Madeira -configuration Debug \
    -destination 'generic/platform=iOS' -derivedDataPath "$DD" \
    IPHONEOS_DEPLOYMENT_TARGET="${MADEIRA_IOS_MIN:-15.0}" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
    ENABLE_DEBUG_DYLIB=NO COMPILER_INDEX_STORE_ENABLE=NO \
    build > "$OUT/xcodebuild.log" 2>&1
rc=$?
set -e
grep -E "error:|warning: .*only available|BUILD (SUCCEEDED|FAILED)|\*\* " "$OUT/xcodebuild.log" | sort -u | head -300 || true
[ $rc -eq 0 ] || { echo "xcodebuild failed ($rc); full log in the xcodebuild-log artifact"; exit $rc; }

APP="$DD/Build/Products/Debug-iphoneos/Madeira.app"

export LC_ALL=C
imports=$(nm -m -u "$APP/Madeira" | grep -v weak | grep "from libc++" | awk '{print $3}' | sort -u)
too_new=$(comm -23 <(echo "$imports") <(grep -v '^#' "$R/ci/libcxx-ios15.6-exports.txt" | sort -u))
if [ -n "$too_new" ]; then
    echo "error: the binary imports libc++ symbols that iOS 16.2 may not have:"
    echo "$too_new"
    exit 1
fi
echo "libc++ imports: $(echo "$imports" | wc -l | tr -d ' '), all in iOS 15.6's libc++"

audited='_MTLCopyAllDevices __availability_version_check _os_sync_wait_on_address _os_sync_wait_on_address_with_timeout _os_sync_wake_by_address_all _os_sync_wake_by_address_any'
weak_c=$(nm -m -u "$APP/Madeira" | grep "weak external" | awk '{print $4}' | grep -v '^_\$s\|^_OBJC_\|^_swift\|^__swift' | sort -u)
unaudited=$(comm -23 <(echo "$weak_c") <(tr ' ' '\n' <<<"$audited" | sort -u))
if [ -n "$unaudited" ]; then
    echo "warning: new weak-imported C functions (NULL on older iOS):"
    echo "$unaudited"
fi
echo "weak C imports audited"

STAGE="$OUT/stage"
rm -rf "$STAGE"; mkdir -p "$STAGE/Payload"
ditto "$APP" "$STAGE/Payload/Madeira.app"
A="$STAGE/Payload/Madeira.app"
rm -rf "$A/PlugIns/MadeiraJITHelper.appex" "$A/Frameworks/StikJIT.framework"
rmdir "$A/PlugIns" 2>/dev/null || true
find "$A" -name '_CodeSignature' -type d -prune -exec rm -rf {} +
rm -f "$A/embedded.mobileprovision"

while IFS= read -r f; do
    if file "$f" | grep -q "Mach-O" && [ "$f" != "$A/Madeira" ]; then
        ldid -S "$f"
    fi
done < <(find "$A" -type f \( -name '*.dylib' -o -perm -u+x \))
ldid -S"$R/ci/trollstore.entitlements" "$A/Madeira"
ldid -e "$A/Madeira"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$A/Info.plist")
MINOS=$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$A/Info.plist")
echo "Madeira $VERSION, MinimumOSVersion $MINOS"
(cd "$STAGE" && zip -qry -9 "$OUT/Madeira-$VERSION-trollstore.tipa" Payload)
ls -l "$OUT"/*.tipa
