#!/bin/sh

INI_FILE=/etc/libiio.ini

#some systems have null in the device tree, so replace those with spaces
#some systems include non-printable chars, or color codes so also remove those.
sanitize_str() {
	echo "$@" |  tr '\0' ' ' | sed -e 's/ $//g' -e 's/\\x1b\[[0-9;]*m//g' | tr -cd '[:print:]\n'
}
sanitize() {
	cat $1 | tr '\0' ' ' | sed -e 's/ $//g' -e 's/\\x1b\[[0-9;]*m//g' | tr -cd '[:print:]\n'
}

#run on ARM
MODEL="/proc/device-tree/model"
# Most ARM systems will fill /sys/firmware;
BASE=$(cat $MODEL)

UNIQUE_ID=$(dmesg | grep SPI-NOR-UniqueID | head -1 | awk '{print $NF}')

# If this is an FMC Board, capture the data
command fru-dump -h >/dev/null 2>&1
if [ "$?" = "0" ] ; then
	for i in $(find /sys/ -name eeprom)
	do
		fru-dump $i > /dev/null 2>&1
		if [ $? -eq "0" ] ; then
			BOARD=$(fru-dump $i -b | grep "Part Number" | awk -F: '{print $2}' | sed 's/^[[:space:]]*//')
			SERIAL=$(fru-dump $i -b | grep "Serial Number" | awk -F: '{print $2}' | sed 's/^[[:space:]]*//')
			NAME=$(fru-dump $i -b | grep "Product Name" | awk -F: '{print $2}' | sed 's/^[[:space:]]*//')
			VENDOR=$(fru-dump $i -b | grep "Manufacturer" | awk -F: '{print $2}' | sed 's/^[[:space:]]*//')
			break
		fi
	done
fi

# remove this from the file, to make sure stale data isn't hanging around
remove() {
	# If this is called with something that is blank, don't do anything.
	if [ ${#1} -eq 0 ] ; then
		return
	fi
	if [ ! -f ${INI_FILE} ] ; then
		return
	fi
	sed -i "/^${1}=/d" ${INI_FILE}
}

# build up ${INI_FILE} and add to it if it is not there
add() {
	if [ ${#1} -eq 0 ] ; then
		return
	fi
	if [ ${#2} -eq 0 ] ; then
		remove $1
		return
	fi

        echo "$1=$2" >> ${INI_FILE}
}

if [ "$1" = "clean" ] ; then
	rm ${INI_FILE}
fi

#prep the file
if [[ -e ${INI_FILE} ]]; then
	rm ${INI_FILE}
fi
touch ${INI_FILE}
echo "[Context Attributes]" >> ${INI_FILE}

# save all we learned into the file
if [ "${BOARD+x}x" != "x" -a "${BASE}x" != "x" ] ; then
	add hw_model "${BOARD} on ${BASE}"
fi
add hw_carrier "${BASE}"
add hw_mezzanine "${BOARD}"
add hw_name "${NAME}"
add hw_vendor "${VENDOR}"
add hw_serial "${SERIAL}"
add unique_id "${UNIQUE_ID}"
add dtoverlay "${OVERLAY}"

exit 0
