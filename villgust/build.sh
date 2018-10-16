
echo "*******************************************************************************"
echo "Setting up environment..."
echo "*******************************************************************************"

set -o errexit

BASE_PWD=$PWD
PATH=".:./asm/bin/:$PATH"
INROM="villgust.nes"
OUTROM="villgust_en.nes"
WLADX="./wla-dx/binaries/wla-6502"
WLALINK="./wla-dx/binaries/wlalink"

cp "$INROM" "$OUTROM"

mkdir -p out

echo "*******************************************************************************"
echo "Building tools..."
echo "*******************************************************************************"

make blackt
make libnes
make

if [ ! -f $WLADX ]; then
  
  echo "********************************************************************************"
  echo "Building WLA-DX..."
  echo "********************************************************************************"
  
  cd wla-dx
    cmake -G "Unix Makefiles" .
    make
  cd $BASE_PWD
  
fi

echo "*******************************************************************************"
echo "Doing initial ROM prep..."
echo "*******************************************************************************"

mkdir -p out
romprep "$OUTROM" "$OUTROM" "out/villgust_chr.bin"

echo "*******************************************************************************"
echo "Patching graphics..."
echo "*******************************************************************************"

mkdir -p out/grp
nes_tileundmp rsrc/font/font_0x1000.png 256 out/grp/font_0x1000.bin
filepatch out/villgust_chr.bin 0x1000 out/grp/font_0x1000.bin out/villgust_chr.bin

echo "*******************************************************************************"
echo "Building tilemaps..."
echo "*******************************************************************************"

#mkdir -p out/maps_raw
#tilemapper_nes tilemappers/title.txt
mkdir -p out/maps
tilemapper_nes tilemappers/title.txt

#mkdir -p out/maps_conv
#mapconv out/maps_conv/

filepatch out/villgust_chr.bin 0x1D010 out/grp/title_grp.bin out/villgust_chr.bin
filepatch "$OUTROM" 0x15292 out/maps/title.bin "$OUTROM"
filepatch "$OUTROM" 0x154D5 rsrc_raw/title_attrmap.bin "$OUTROM"

# echo "*******************************************************************************"
# echo "Patching other graphics..."
# echo "*******************************************************************************"
# 
# #rawgrpconv rsrc/misc/shiro.png rsrc/misc/shiro.txt out/sanma_chr.bin out/sanma_chr.bin
# #rawgrpconv rsrc/misc/kyojin.png rsrc/misc/kyojin.txt out/sanma_chr.bin out/sanma_chr.bin
# 
# for file in rsrc/misc/*.txt; do
#   bname=$(basename $file .txt)
#   rawgrpconv rsrc/misc/$bname.png rsrc/misc/$bname.txt out/villgust_chr.bin out/villgust_chr.bin
# done

echo "*******************************************************************************"
echo "Building script..."
echo "*******************************************************************************"

mkdir -p out/script
#mkdir -p out/script/credits
mkdir -p out/script/maps
scriptconv script/ table/villgust_en.tbl out/script/
# scriptconv_raw script/names.txt table/sanma_en.tbl out/script/names.bin
# #scriptconv_raw script/tilemaps3.txt table/sanma_en.tbl out/script/tilemaps3.bin

#filepatch "$OUTROM" 0x43CE out/script/cybergong_inout.bin "$OUTROM"
filepatch "out/villgust_chr.bin" 0x3BDC0 out/script/battle_inventory.bin "out/villgust_chr.bin"

# echo "*******************************************************************************"
# echo "Building compression table..."
# echo "*******************************************************************************"
# 
# mkdir -p out/cmptbl
# cmptablebuild table/villgust_en.tbl out/cmptbl/cmptbl.bin

echo "********************************************************************************"
echo "Applying ASM patches..."
echo "********************************************************************************"

mkdir -p "out/asm"
cp "$OUTROM" "asm/villgust.nes"

cd asm
  # apply hacks
  ../$WLADX -I ".." -o "boot.o" "boot.s"
  ../$WLALINK -v linkfile villgust_build.nes
cd $BASE_PWD

mv -f "asm/villgust_build.nes" "$OUTROM"
rm "asm/villgust.nes"
rm asm/*.o

echo "*******************************************************************************"
echo "Finalizing ROM..."
echo "*******************************************************************************"

romfinalize "$OUTROM" "out/villgust_chr.bin" "$OUTROM"

echo "*******************************************************************************"
echo "Success!"
echo "Output file:" $OUTROM
echo "*******************************************************************************"
