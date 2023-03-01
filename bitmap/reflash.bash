#!/usr/local/bin/bash

mcu=${1?'error: no target chip given'}
ifs=${2?'error: no input file system path given'}
upp=${3?'error: no upload port given'}

esptool=$( type -P esptool ) ||
	esptool=$( type -P esptool.py ) ||
		esptool=$( type -P esptool_py ) || 
			{ echo "error: tool not found: esptool|esptool.py|esptool_py"; exit 2; }

mklittlefs=$( type -P mklittlefs ) ||
	{ echo "error: tool not found: mklittlefs"; exit 3; }

now() { date +'%Y%m%d-%H%M%S'; }

untouched() { 
    if [[ ${#} -gt 0 ]]; then
        local clean=$( sed -E 's/\/+$//' <<< "${1}" )
        local base=${clean} curr=${clean} i=0
        while [[ -e "${curr}" ]]; do
            curr="${base}@$((++i))"
        done
        printf -- '%s' "${curr}"
    fi
}

tmpdir() { 
    for tmp in {${HOME}/{.{local/,},},.}tmp "$( dirname "$( mktemp -ut )" )"; do
        if [[ -r "${tmp}" && -w "${tmp}" && -x "${tmp}" ]]; then
            echo "${tmp}"
            return
        fi
    done
}

mkdirt() { 
    path=$( untouched "${1:-$( tmpdir )}/$( now )" );
    if mkdir -p "${path}"; then
        echo "${path}"
    fi
}

set -o errexit

ofs="$( mkdirt )/${ifs##*/}.iso"

cleanup() { rm -rf "${ofs%/*}"; }

trap cleanup EXIT

# partition table must have offset defined (cannot be blank or automatically-computed)
csv='../partitions.csv'

param=$( command grep -oP '^\s*spiffs\s*,\s*data\s*,\s*spiffs\s*,\s*\K[^,]+\s*,\s*[^,]+' "${csv}" )

bytes() {
	v=${1^^}
	case ${v} in
		0X*) echo $(( ${v} )) ;;
		*K) echo $(( ${v%K} * 1024 )) ;;
		*M) echo $(( ${v%M} * 1024 * 1024 )) ;;
	esac
}

offs=$( bytes ${param%,*} )
size=$( bytes ${param#*,} )

set -x
debug=5
blksz=4096
pagsz=256
flaio=qio
flahz=80m
flasz=4MB
"${mklittlefs}" -c "${ifs}" -b ${blksz} -p ${pagsz} -s ${size} -d ${debug} -- "${ofs}" > "${0%.bash}.log"
set +x

"${mklittlefs}" -l "${ofs}"

"${esptool}" --chip "${mcu}" --port "${upp}" --after no_reset write_flash -ff ${flahz} -fm ${flaio} -fs ${flasz} -z ${offs} "${ofs}"
