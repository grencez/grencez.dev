#!/bin/sh

# Example: sudo ./backup.sh /dev/sdb1 --keyfile ~/.my/secretkeyfile

# Root device and boot device (we back up both).
rootdev=$(grep -o -e '^\S\+\s\+/\s' /etc/fstab  | grep -o -e '^\S*')
bootdev=$(grep -o -e '^\S\+\s\+/boot\s' /etc/fstab  | grep -o -e '^\S*')

backname="backupimage"

backmnt="/root/backmnt"
rootmnt="/root/rootmnt"

backdev="$1"
shift

backkey=""
if [ "$1" = "--keyfile" ]
then
  shift
  backkey="$1"
  shift
fi

dstpath=""
if [ -n "$1" ]
then
  dstpath="$1"
  shift
fi

if [ -z "$backdev" ]
then
  echo "Usage: $0 <device> [--keyfile <keyfile>] [<dstpath>]" >&2
  echo "  Where <keyfile> is the full path to the luks key to decrypt your device." >&2
  echo "  And <dstpath> is the path on the backup device to copy to (the computer name by default)" >&2
  exit 1
fi

if [ -z "$dstpath" ]
then
  dstpath=$(hostname | grep -o -e '^[^\.]*')
fi

echo "root dev: $rootdev"
echo "boot dev: $bootdev"
echo "backup dev: $backdev"
echo "backup key: $backkey"
echo "will mount root on: $rootmnt"
echo "will mount backup on: $backmnt"
echo "will rsync root to: $backmnt/$dstpath"
echo "Do it? (Y/N)" >&2
read -r decision

if [ 'Y' != "$decision" -a 'y' != "$decision" ]
then
  echo "Perhaps another time then." >&2
  exit 1
fi
echo "Let's go!" >&2



assert_count=0

assertgood()
{
  let ++assert_count
  if [ 0 != "$1" ]
  then
    printf 'Error, bailing out on assertion #%d.\n' "$assert_count" >&2
    exit 1
  fi
}

run()
{
  echo "$@"
  "$@"
  assertgood $?
}

run mkdir -p "$backmnt" "$rootmnt"

if [ -z "$backkey" ]
then
  run cryptsetup luksOpen "$backdev" "$backname"
else
  run cryptsetup luksOpen -d "$backkey" "$backdev" "$backname"
fi
run mount "/dev/mapper/$backname" "$backmnt"

run mount "$rootdev" "$rootmnt"
run mount "$bootdev" "$rootmnt/boot"

run mkdir -p "$backmnt/$dstpath"
run rsync -a --delete "$rootmnt/" "$backmnt/$dstpath/"

run umount "$rootmnt/boot" "$rootmnt" "$backmnt"
run cryptsetup luksClose "$backname"

run rmdir "$rootmnt" "$backmnt"

