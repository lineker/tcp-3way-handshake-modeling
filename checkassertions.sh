#!/usr/bin/env bash

# Make sure we're in the right directory
cd "`dirname "$0"`"

modelCheck() {
	echo "       Checking: $1"
	if ./modelcheck.sh "$@" &> /dev/null; then
		echo "[ OK ] Success: $1"
		return 0
	else
		echo "[FAIL] Failure: $1"
		echo "       For output, run modelcheck.sh:"
		echo "           ./modelcheck.sh '$1'"
		return 1
	fi
}

modelCheck tcp.pml || exit 1

while IFS= read -d $'\0' -r file; do
	modelCheck "$file" || exit 1
done < <(find assertions -name '*.pml' -type f -print0)
