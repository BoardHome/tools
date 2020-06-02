#!/bin/bash
pause()
{
echo "Press any key to quit:"
read -n1 -s key
exit 1
}
echo "start to make update.img..."
if [ ! -f "Image/parameter" -a ! -f "Image/parameter.txt" ]; then
	echo "Error:No found parameter!"
	exit 1
fi
if [ ! -f "package-file" ]; then
	echo "Error:No found package-file!"
	exit 1
fi

ALIGN()
{
    X=$1
    A=$2
    OUT=$(($((${X} + ${A} -1 ))&$((~$((${A}-1))))))
    printf 0x%x ${OUT}
}

FSIZE=$(stat $(readlink -f Image/rootfs.img) -c %b)
PSIZE=$(ALIGN $((${FSIZE}+204800)) 512)
PARA_FILE=$(readlink -f Image/parameter.txt)

ORIGIN=$(grep -Eo "0x[0-9a-fA-F]*@0x[0-9a-fA-F]*\(rootfs" $PARA_FILE)
NEWSTR=$(echo $ORIGIN | sed "s/.*@/${PSIZE}@/g")
OFFSET=$(echo $NEWSTR | grep -Eo "@0x[0-9a-fA-F]*" | cut -f 2 -d "@")
NEXT_START=$(printf 0x%x $(($PSIZE + $OFFSET)))
sed -i.orig "s/$ORIGIN/$NEWSTR/g" $PARA_FILE
sed -i "/^CMDLINE.*/s/-@0x[0-9a-fA-F]*/-@$NEXT_START/g" $PARA_FILE

./afptool -pack ./ Image/update.img || pause
./rkImageMaker -RK180A Image/MiniLoaderAll.bin Image/update.img update.img -os_type:androidos || pause
echo "Making ./Image/update.img OK."
#echo "Press any key to quit:"
#read -n1 -s key
mv ${PARA_FILE}.orig ${PARA_FILE}
exit $?
