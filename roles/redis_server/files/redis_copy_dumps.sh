#!/bin/sh

set -eo pipefail

DEST=/home/lbkp/redis

[ -d $DEST ] || mkdir -p $DEST

echo "Saving dump.rdb"
/usr/bin/redis-cli save
for FILE in dump.rdb appendonly.aof; do
  if [ -e /var/lib/redis/$FILE ]; then
    echo "Copying /var/lib/redis/$FILE to $DEST"
    cp /var/lib/redis/$FILE $DEST/
  fi
done
