#!/usr/bin/env bash

# Make sure we're in the right directory
cd "`dirname "$0"`"

mutantCheck() {
	echo "       Checking mutant: $1"
	tempFile="$1.mutant"
	while IFS= read -d $'\0' -r file; do
		echo "         > Trying assertion: $file"
		cat "$1" | sed 's|tcp.pml"|'"$file"'"|' > "$tempFile"
		./modelcheck.sh "$tempFile" &> /dev/null
		returnCode="$?"
		if [ "$returnCode" -eq 1 ]; then
			echo "[ OK ] Assertion $file caught mutant $1"
			rm -f "$tempFile" "$tempFile.trail"
			return 0
		elif [ ! "$returnCode" -eq 0 ]; then
			echo "         > [WARN] Assertion $file failed to compile when checking for mutant $1"
		fi
	done < <(find assertions -name '*.pml' -type f -print0)
	rm -f "$tempFile" "$tempFile.trail"
	echo "[FAIL] Mutant $1 wasn't caught by any assertion."
	return 1
}

while IFS= read -d $'\0' -r file; do
	mutantCheck "$file" || exit 1
done < <(find "${1:-"mutants"}" -name '*.pml' -type f -print0)
