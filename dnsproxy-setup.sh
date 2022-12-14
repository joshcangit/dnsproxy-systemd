#!/bin/sh
REPO="https://github.com/AdguardTeam/dnsproxy"
CMDS=$(type -P {aria2c,curl,wget})
DIR="/opt/adguard"
TMP_DIR=$(mktemp -d)
url() {
  case "$CMDS" in
    *curl*) curl -ISs $1;;
    *wget*) wget --max-redirect=0 $1 2>&1;;
  esac
}
url "${REPO}/releases/latest" | grep -i ^location: | cut -d' ' -f2 | cut -d? -f1 | awk -F/ '{print $NF}' >${DIR}/LATEST
LATEST=$(sed 's/\r//g' ${DIR}/LATEST)
download() {
  local FILE="dnsproxy-${1}-${LATEST}.tar.gz"
  local URL="${REPO}/releases/download/${LATEST}/${FILE}"
  case "$CMDS" in
    *aria2c*)
    aria2c $URL -d "$TMP_DIR" -o "$FILE" -j5 -x10 -s8 -k1M --optimize-concurrent-downloads --header="Accept-Encoding: zstd, gzip, deflate";;
    *curl*)
    curl -L $URL -o "$TMP_DIR/$FILE" --compressed -H "Accept-Encoding: zstd, gzip, deflate";;
    *wget*)
    wget $URL -P "$TMP_DIR" -O "$FILE" --header="Accept-Encoding: zstd, gzip, deflate";;
  esac
  local TPATH=$(tar -ztf $TMP_DIR/$FILE | grep dnsproxy$)
  local RDIR=$(echo $TPATH | sed 's/^\.\///;s/dnsproxy$//')
  tar -C $TMP_DIR -zxf $TMP_DIR/$FILE $TPATH
  mv -f $TMP_DIR/${RDIR}dnsproxy $TMP_DIR/dnsproxy && chown root:root $TMP_DIR/dnsproxy
}
sysctlfn() {
  local SERVICE="adguard-dnsproxy.service"
  if [ $(systemctl list-unit-files "$SERVICE" | wc -l) -gt 3 ]; then
  systemctl $1 $SERVICE
  fi
}
[ -d "$DIR" ] || mkdir $DIR
if [ -f "$DIR/dnsproxy" ]; then
  VERSION=$($DIR/dnsproxy --version | awk '{print $NF}')
  OUTPUT=$(printf "$VERSION\n$LATEST" | sed '/^$/d' | sort -Vr | head -1)
  if [ "$VERSION" != "$OUTPUT" ]; then
    download "${1}"
    sysctlfn stop
    [ -f "$TMP_DIR/dnsproxy" ] && mv -f $TMP_DIR/dnsproxy $DIR/dnsproxy && rm -rf $TMP_DIR
    sysctlfn start
  fi
else
  download "${1}"
  [ -f "$TMP_DIR/dnsproxy" ] && mv -f $TMP_DIR/dnsproxy $DIR/dnsproxy && rm -rf $TMP_DIR
  ln -sf $DIR/dnsproxy /usr/local/sbin/dnsp
fi
