#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TSoundFile.h"
#include "nes/NesPattern.h"
#include <string>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Nes;

int main(int argc, char* argv[]) {
  
  TBufStream ifs(1);
  ifs.open("villgust_noheader.nes");
  int numEntries = 0x4F;
  
  for (int i = 0; i < numEntries; i++) {
    ifs.seek(0x9B41 + (i * 3));
    int x = ifs.readu8();
    int y = ifs.readu8();
    int length = ifs.readu8();
    
    std::cout << "tt1PosTable_" << std::hex << i << ":" << std::endl;
    std::cout << "  .db $" << std::hex << x
      << ",$" << std::hex << y
      << ",$" << std::hex << length << std::endl;
  }
  
  return 0;
}
