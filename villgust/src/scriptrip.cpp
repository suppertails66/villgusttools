#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TThingyTable.h"
#include "nes/NesRom.h"
#include "nes/NesPattern.h"
#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <fstream>

using namespace std;
using namespace BlackT;
using namespace Nes;

TThingyTable table;
TThingyTable tiletable;
TThingyTable charaTable;

string as2bHex(int value) {
  string str = TStringConversion::intToString(value,
          TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = "0" + str;
  return str;
}

string nextAsRaw(TStream& ifs) {
  string str;
  str += "<$" + as2bHex(ifs.readu8()) + ">";
  return str;
}

void ripScript(TStream& ifs, ostream& ofs, int limit = -1) {
  
  bool limitReached = false;
  
  if ((limit != -1) && (ifs.tell() >= limit)) goto done;
  
  ofs << "// ";
  
  while (true) {
    if ((limit != -1) && (ifs.tell() >= limit)) {
      limitReached = true;
      break;
    }
    
    TThingyTable::MatchResult match = table.matchId(ifs);
    
    if (match.id == -1) {
//      ofs << "[???]";
      ofs << "<$" << as2bHex(ifs.readu8()) << ">";
    }
    else {
      
      string str = table.getEntry(match.id);
      
      if (match.id != 0x00)
        ofs << str;
      
      // terminator
      if (match.id == 0x00) {
//        terminatorString = str;
        ofs << endl;
        break;
      }
      // linebreak
      else if (match.id == 0x44) {
        ofs << endl;
        ofs << "// ";
      }
    }
  }
  
  if (limitReached) {
    ofs << endl;
  }
  
done:
  
  ofs << endl << endl << "#END()" << endl << endl;
}

void ripBank(TStream& ifs, ostream& ofs,
             int tableStart, int numEntries,
             int bankEnd = -1,
             int bankOffset = 0x8000,
             int bankSize = 0x1000) {
  int bankBase = (tableStart / bankSize) * bankSize;
  if (bankEnd == -1) bankEnd = bankBase + bankSize;
  for (int i = 0; i < numEntries; i++) {
    ifs.seek(tableStart + (i * 2));
    int ptr = ifs.readu16le();
    int addr = (ptr - bankOffset) + bankBase;
    
    int limit;
    if (i != (numEntries - 1)) {
      limit = ((ifs.readu16le()) - ptr) + addr;
    }
    else {
      limit = bankEnd;
    }
    
    ifs.seek(addr);
    ofs << "// Script "
      << TStringConversion::intToString(tableStart,
          TStringConversion::baseHex)
      << "-"
      << TStringConversion::intToString(i,
          TStringConversion::baseHex)
      << " ("
      << TStringConversion::intToString(addr,
          TStringConversion::baseHex)
      << ")" << endl;
    ripScript(ifs, ofs, limit);
  }
  
  
}

void ripTilemap(TStream& ifs, ostream& ofs,
                int addr,
                int w, int h) {
  for (int k = 0; k < 2; k++) {
    ifs.seek(addr);
    for (int j = 0; j < h; j++) {
      if (k == 0) ofs << "// ";
      for (int i = 0; i < w; i++) {
        int next = (unsigned char)ifs.get();
        
        if (!tiletable.hasEntry(next)) {
          ofs << "<$" << as2bHex(next) << ">";
        }
        else {
          string str = tiletable.getEntry(next);
          ofs << str;
        }
        
      }
      ofs << endl;
    }
  }
  
  ofs << endl << endl << "#END()" << endl << endl;
}

/*void ripEnumList(TStream& ifs, ostream& ofs,
             int tableStart, int numEntries,
             int bankEnd = -1,
             int bankOffset = 0x8000) {
  int bankBase = (tableStart / 0x2000) * 0x2000;
  if (bankEnd == -1) bankEnd = bankBase + 0x2000;
  for (int i = 0; i < numEntries; i++) {
    ifs.seek(tableStart + (i * 2));
    int ptr = ifs.readu16le();
    int addr = (ptr - bankOffset) + bankBase;
    
    int limit;
    if (i != (numEntries - 1)) {
      limit = ((ifs.readu16le()) - ptr) + addr;
    }
    else {
      limit = bankEnd;
    }
    
    ifs.seek(addr);
    ofs << "// Enum list "
      << TStringConversion::intToString(tableStart,
          TStringConversion::baseHex)
      << "-"
      << TStringConversion::intToString(i,
          TStringConversion::baseHex)
      << " ("
      << TStringConversion::intToString(addr,
          TStringConversion::baseHex)
      << ")" << endl;
    
    // number of items in list (or zero if the game ignores it?)
    ofs << nextAsRaw(ifs) << endl;
    ripScript(ifs, ofs, limit, false, 0xFA, 0xFF);
  }
  
  
} */

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Kouryuu Densetsu Villgust Gaiden script extractor" << endl;
    cout << "Usage: " << argv[0]
      << " <rom> <table> <outprefix>" << endl;
    
    return 0;
  }
  
  table.readSjis(string(argv[2]));
  tiletable.readSjis(string("table/villgust_tilemap.tbl"));
  string outprefix = string(argv[3]);
  
  TBufStream ifs(1);
  ifs.open(argv[1]);
  
/*  {
    ofstream ofs((outprefix + "script_0B586.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x0B586, 0x35, -1, 0xA000, 0x2000);
  }
  
  {
    ofstream ofs((outprefix + "script_1AFEE.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x1AFEE, 0x110, -1, 0xA000, 0x2000);
  }
  
  {
    ofstream ofs((outprefix + "script_4E000.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x4E000, 0x80, -1, 0x1000, 0x1000);
  }
  
  {
    ofstream ofs((outprefix + "script_4F000.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x4F000, 0x60, -1, 0x1000, 0x1000);
  }
  
  {
    ofstream ofs((outprefix + "script_5C000.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x5C000, 0x60, -1, 0x1000, 0x1000);
  }
  
  {
    ofstream ofs((outprefix + "script_5D000.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x5D000, 0x68, -1, 0x1000, 0x1000);
  }
  
  {
    ofstream ofs((outprefix + "script_5E000.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x5E000, 0x51, -1, 0x1000, 0x1000);
  }
  
  {
    ofstream ofs((outprefix + "script_57000.txt").c_str(), ios_base::binary);
    ripBank(ifs, ofs, 0x57000, 0x9, -1, 0x1000, 0x1000);
  }
  
  {
    ofstream ofs((outprefix + "battle_inventory.txt").c_str(), ios_base::binary);
    ripTilemap(ifs, ofs, 0x5BDC0, 0x20, 18);
  } */
  
//  {
//    ofstream ofs((outprefix + "title_options.txt").c_str(), ios_base::binary);
//    ripTilemap(ifs, ofs, 0x5BDC0, 0x20, 18);
//  }
  
  
  return 0;
}
