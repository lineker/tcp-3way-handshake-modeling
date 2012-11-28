#!/usr/bin/env bash

# Make sure we're in the right directory
cd "`dirname "$0"`"

# Remove possible leftover files
rm -f pan.* tcp.model
# Create pan.c file
if ! spin -a tcp.pml; then
	echo 'Failed to create pan.c file' >&2
	exit 1
fi
# Compile it
if ! gcc -DSAFETY pan.c -o tcp.model; then
	echo 'Failed to compile pan.c file' >&2
	exit 1
fi
# Run it
./tcp.model
# Remove cruft
rm -f pan.* tcp.model
# If there's a trail file, show it
if [ -f tcp.pml.trail ]; then
	spin -t tcp.pml
	echo 'End of trail file' >&2
	exit 1
fi
# Otherwise, exit
echo 'No trail file present. Victory!' >&2
