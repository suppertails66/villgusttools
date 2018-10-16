#include "villgust/VillgustLineWrapper.h"
#include <iostream>

using namespace BlackT;

namespace Nes {

VillgustLineWrapper::VillgustLineWrapper(BlackT::TStream& src__,
                ResultCollection& dst__,
                const BlackT::TThingyTable& thingy__,
                int xSize__,
                int ySize__)
  : TLineWrapper(src__, dst__, thingy__, xSize__, ySize__),
    waitPending(false) {
  
}

int VillgustLineWrapper::widthOfKey(int key) {
  // multi-space chars
  if ((key >= 0x02) && (key <= 0x0D)) {
    return key;
  }
  
  // name
  if ((key == 0x40)) return 7;
  
  // item
  if ((key == 0x4A)) return 21;
  
  // number (note: we're pretty much screwed with this one -- numbers may have
  // an arbitrary number of digits)
  if ((key == 0x41)) return 4;
  
  // command ops
  if (
      // end
      (key == 0x00)
      // other
      || ((key >= 0x40) && (key <= 0x4B))
      // close
      || (key == 0x7F)
     ) {
    return 0;
  }
  
  return 1;
}

bool VillgustLineWrapper::isWordDivider(int key) {
  if (
      // space
      ((key >= 0x01) && (key <= 0x0D))
      // wait
      || (key == 0x42)
      // box clear
      || (key == 0x43)
      // linebreak
      || (key == 0x44)
     ) return true;
  
  return false;
}

bool VillgustLineWrapper::isLinebreak(int key) {
  if (key == 0x44) return true;
  
  return false;
}

bool VillgustLineWrapper::isBoxClear(int key) {
  if (key == 0x43) return true;
  // wait commands also clear the box.
  // yet for some reason most waits are followed by a clear anyway?
  if (key == 0x42) return true;
  
  return false;
}

void VillgustLineWrapper::onBoxFull() {
//  if (lineHasContent) {
    std::string content;
  //      std::cerr << "x" << std::endl;
//    if (!waitPending) {
    if (lineHasContent) {
      // wait
      content = thingy.getEntry(0x42);
      currentScriptBuffer.write(content.c_str(), content.size());
//    }
    }
    // clear
    content = thingy.getEntry(0x43);
    currentScriptBuffer.write(content.c_str(), content.size());
    // linebreak
    outputLinebreak();
//    content = thingy.getEntry(0x44);
//    currentScriptBuffer.write(content.c_str(), content.size());
//    stripCurrentPreDividers();
    
//    currentScriptBuffer.put('\n');
    currentScriptBuffer.put('\n');
    xPos = 0;
    yPos = 0;
//  }

//  std::cerr << "WARNING: line " << lineNum << ":" << std::endl;
//  std::cerr << "  overflow at: " << std::endl;
//  std::cerr << streamAsString(currentScriptBuffer)
//    << std::endl
//    << streamAsString(currentWordBuffer) << std::endl;
}

int VillgustLineWrapper::linebreakKey() {
  return 0x44;
}

void VillgustLineWrapper::onSymbolAdded(int key) {
  if (key == 0x42) waitPending = true;
  else {
    if (
        // end
        (key == 0x00)
        // other
        || ((key >= 0x40) && (key <= 0x4B))
        // close
        || (key == 0x7F)
       ) {
      
    }
    else {
      waitPending = false;
    }
  }
}

}
