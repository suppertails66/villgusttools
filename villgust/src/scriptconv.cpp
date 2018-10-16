#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TGraphic.h"
#include "util/TStringConversion.h"
#include "util/TPngConversion.h"
#include "util/TCsv.h"
#include "util/TThingyTable.h"
#include "nes/NesPattern.h"
#include "villgust/VillgustLineWrapper.h"
#include "villgust/VillgustScriptReader.h"
#include <string>
#include <vector>
#include <iostream>

using namespace std;
using namespace BlackT;
using namespace Nes;

const static int scriptBaseAddr = 0x0000;
const static int maxScriptBankSize = 0x2000;
const static int bankSize = 0x2000;

TThingyTable table;
//TThingyTable nameTable;
std::vector<VillgustScriptReader::ResultCollection> sets;

void packScripts(const VillgustScriptReader::ResultCollection& set,
                   TStream& ofs, int slotBase = 0x8000, int basePos = 0x0000) {
  int indexBase = ofs.tell();
  int putpos = ofs.tell() + (set.size() * 2);
  for (unsigned int i = 0; i < set.size(); i++) {
    const VillgustScriptReader::ResultString& resultString = set[i];
    ofs.seek(indexBase + (i * 2));
    ofs.writeu16le((putpos % bankSize) + slotBase + basePos);
    ofs.seek(putpos);
    ofs.write(resultString.str.c_str(), resultString.str.size());
    putpos += resultString.str.size();
  }
}

void writeScriptsRaw(const VillgustScriptReader::ResultCollection& set,
                   TStream& ofs) {
  for (unsigned int i = 0; i < set.size(); i++) {
    const VillgustScriptReader::ResultString& resultString = set[i];
    ofs.write(resultString.str.c_str(), resultString.str.size());
  }
}

void writeAsmSet(const VillgustScriptReader::ResultCollection& set,
                 string baseName, string baseBinName,
                 string outIncName) {
  
  {
    std::ofstream ofs((outIncName +  + "_index.inc").c_str());
    for (unsigned int i = 0; i < set.size(); i++) {
      string name = baseName
                    + "_"
                    + TStringConversion::intToString(i);
      ofs << ".dw " << name << endl;
    }
  }
  
  {
    std::ofstream ofs((outIncName +  + "_data.inc").c_str());
    for (unsigned int i = 0; i < set.size(); i++) {
      TBufStream binofs(0x1000);
      string name = baseName
                    + "_"
                    + TStringConversion::intToString(i);
      string binname = baseBinName
                  + TStringConversion::intToString(i)
                  + ".bin";
      
      const VillgustScriptReader::ResultString& resultString = set[i];
      binofs.write(resultString.str.c_str(), resultString.str.size());
      
      ofs << name << ":" << endl;
      ofs << "  .incbin \"" << binname << "\"" << endl;
      
      binofs.save(binname.c_str());
    }
  }
  
  {
    std::ofstream ofs((outIncName +  + ".inc").c_str());
    ofs << ".include \"" << (outIncName +  + "_index.inc") + "\"" << endl;
    ofs << ".include \"" << (outIncName +  + "_data.inc") + "\"" << endl;
  }
  
}

void addSet(string filename) {
  cout << "adding set " << filename << endl;
  
  VillgustScriptReader::ResultCollection set;
//  TIfstream ifs((filename).c_str(), ios_base::binary);
  TBufStream ifs(1);
  ifs.open((filename).c_str());
  VillgustScriptReader(ifs, set, table)();
  sets.push_back(set);
}

void wrapSet(string filename, string outfile) {
  cout << "wrapping set " << filename << " to " << outfile << endl;

  TBufStream ifs(1);
  ifs.open(filename.c_str());
  TLineWrapper::ResultCollection set;
  VillgustLineWrapper(ifs, set, table, 22, 4)();
  
  TBufStream ofs(0x10000);
  for (unsigned int i = 0; i < set.size(); i++) {
    const TLineWrapper::ResultString& resultString = set[i];
    ofs.write(resultString.str.c_str(), resultString.str.size());
  }
  ofs.save(outfile.c_str());
}

void wrapAndPackSet(string prefix, string outprefix,
                    string filenameBase, string outFilenameBase) {
  wrapSet((prefix + filenameBase + ".txt"),
          (outprefix + outFilenameBase + "_wrapped.txt"));
  
  {
    TBufStream ifs(1);
    ifs.open((outprefix + outFilenameBase + "_wrapped.txt").c_str());
    VillgustScriptReader::ResultCollection set;
    VillgustScriptReader(ifs, set, table)();
    
    writeAsmSet(set,
                outFilenameBase,
                outprefix + "maps/" + outFilenameBase + "_",
                outprefix + "maps/" + outFilenameBase);
    
  }
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Kouryuu Densetsu Villgust Gaiden script converter" << endl;
    cout << "Usage: " << argv[0]
      << " <inprefix> <table> <outprefix>" << endl;
    
    return 0;
  }
  
  std::string prefix = std::string(argv[1]);
  std::string outprefix = std::string(argv[3]);
  
//  table.readUtf8(string(argv[2]));
  table.readSjis(string(argv[2]));
  
//  nameTable.readSjis(string(argv[3]));

  // screw passing in parameters, I have to rewrite this damn thing
  // every time anyway
  TThingyTable tiletable;
  tiletable.readSjis("table/villgust_tilemap_en.tbl");

//  sets.resize(numSets);

/*  {
    TBufStream ifs(1);
    ifs.open((prefix + "script_4E000.txt").c_str());
    TLineWrapper::ResultCollection set;
    VillgustLineWrapper(ifs, set, table, 22, 4)();
    
    TBufStream ofs(0x10000);
//    writeScriptsRaw(set, ofs);
    for (unsigned int i = 0; i < set.size(); i++) {
      const TLineWrapper::ResultString& resultString = set[i];
      ofs.write(resultString.str.c_str(), resultString.str.size());
    }
    ofs.save((outprefix + "script_4E000_wrapped.txt").c_str());
  } */
  
  wrapAndPackSet(prefix, outprefix, "script_0B586", "script0B586");
  wrapAndPackSet(prefix, outprefix, "script_1AFEE", "script1AFEE");
  wrapAndPackSet(prefix, outprefix, "script_4E000", "script4E000");
  wrapAndPackSet(prefix, outprefix, "script_4F000", "script4F000");
  wrapAndPackSet(prefix, outprefix, "script_5C000", "script5C000");
  wrapAndPackSet(prefix, outprefix, "script_5D000", "script5D000");
  wrapAndPackSet(prefix, outprefix, "script_5E000", "script5E000");
  wrapAndPackSet(prefix, outprefix, "script_57000", "script57000");
  
  {
    TBufStream ifs(1);
    ifs.open((prefix + "battle_inventory" + ".txt").c_str());
    VillgustScriptReader::ResultCollection set;
    VillgustScriptReader(ifs, set, tiletable)();
    
    TBufStream ofs(0x10000);
    writeScriptsRaw(set, ofs);
    ofs.save((outprefix + "battle_inventory"
                + ".bin").c_str());
  }
  
  {
    TBufStream ifs(1);
    ifs.open((prefix + "title_options" + ".txt").c_str());
    VillgustScriptReader::ResultCollection set;
    VillgustScriptReader(ifs, set, tiletable)();
    
    TBufStream ofs(0x10000);
    writeScriptsRaw(set, ofs);
    ofs.save((outprefix + "title_options"
                + ".bin").c_str());
  }
  
/*  wrapSet((prefix + "script_4E000.txt"),
          (outprefix + "script_4E000_wrapped.txt"));
  
  {
    TBufStream ifs(1);
    ifs.open((outprefix + "script_4E000_wrapped.txt").c_str());
    VillgustScriptReader::ResultCollection set;
    VillgustScriptReader(ifs, set, table)();
    
    writeAsmSet(set,
                "script4E000",
                outprefix + "maps/script4E000_",
                outprefix + "maps/script4E000.inc");
    
  } */
  
//  addSet(prefix + "script_4E000_wrapped.txt");
//  for (unsigned int i = 0; i < sets.size(); i++) {
//    TBufStream ofs(0x10000);
//    writeAsmSet(sets[i], ofs, 0x8000, 0x0000);
//  }

/*  addSet(prefix + "script_0B586.txt");
  addSet(prefix + "script_1AFEE.txt");
  addSet(prefix + "script_4E000.txt");
  addSet(prefix + "script_4F000.txt");
  addSet(prefix + "script_5C000.txt");
  addSet(prefix + "script_5D000.txt");
  addSet(prefix + "script_5E000.txt"); */
  
/*  for (unsigned int i = 0; i < sets.size(); i++) {
    TBufStream ofs(0x10000);
    packScripts(sets[i], ofs, 0x8000, 0x0000);
    
    if (ofs.size() >= maxScriptBankSize) {
      cerr << "Error: section " << i << " too big ("
        << ofs.size() << " bytes, max " << maxScriptBankSize << ")" << endl;
      return 1;
    }
    
//    ofs.write(sets[i].c_str(), sets[i].size());
    ofs.save((outprefix + "script_" + TStringConversion::intToString(i)
                + ".bin").c_str());
  } */
  
/*  {
    TBufStream ifs(1);
    ifs.open((prefix + "menus" + ".txt").c_str());
    VillgustScriptReader::ResultCollection set;
    VillgustScriptReader(ifs, set, table_nocmp, table_nocmp, false)();
    
    TBufStream ofs(0x10000);
    writeScriptsRaw(set, ofs);
    ofs.save((outprefix + "menus"
                + ".bin").c_str());
  }
  
  {
    TIfstream ifs((prefix + "intro_text"
      + ".txt").c_str(), ios_base::binary);
    VillgustScriptReader::ResultCollection set;
    VillgustScriptReader(ifs, set, table, table, false)();
    
    TBufStream ofs(0x10000);
    packScripts(set, ofs, 0xBF00);
    ofs.save((outprefix + "intro_text"
                + ".bin").c_str());
  } */
  
  return 0;
}
