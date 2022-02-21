#!/bin/bash
#rsync -a(rlptgoD)R --numeric-ids
src="${1:-/path/to/source}"
dst="${2:-/path/to/target}"
backupDepth=${backupDepth:-7}
pathBak0="${pathBak0:-data}"
dateCmd="${dateCmd:-date}"
logName="${logName:-rsync-incremental-backup_$(${dateCmd} +%Y-%m-%d)_$(${dateCmd} +%H-%M-%S).log}"
ownFolderName="${ownFolderName:-.rsync-incremental-backup}"
logFolderName="${logFolderName:-log}"

rsync -ahv${checksumFlag} --progress --timeout="${timeout}" --delete -W --link-dest="${bak1}/" \
	--log-file="${logFile}" --exclude="${ownFolderName}/" --chmod=+r --include-from="${inclusionFilePath}" \
	--exclude-from="${exclusionFilePath}" ${additionalFlags} "${src}/" "${bak0}/"