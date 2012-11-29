#!/usr/bin/env bash

# Make sure we're in the right directory
cd "`dirname "$0"`"

pmlFile="${1:-"tcp.pml"}"

COMPILER=gcc
if [ "$pmlFile" == "tcp.pml" ]; then
	COMPILER='gcc -DSAFETY'
fi

cd "`dirname "$pmlFile"`"
pmlFile="`basename "$pmlFile"`"

# Remove possible leftover files
rm -f pan.* "$pmlFile".model "$pmlFile".trail
# Create pan.c file
if ! spin -a "$pmlFile"; then
	echo 'Failed to create pan.c file' >&2
	exit 1
fi
# Compile it
if ! $COMPILER pan.c -o "$pmlFile".model; then
	echo 'Failed to compile pan.c file' >&2
	exit 1
fi
# Run it
./"$pmlFile".model
# Remove cruft
rm -f pan.* "$pmlFile".model
# If there's a trail file, show it
if [ -f "$pmlFile".trail ]; then
	spin -t "$pmlFile"
	echo 'End of trail file' >&2
	exit 1
fi
# Otherwise, exit
echo 'No trail file present. Victory!' >&2
