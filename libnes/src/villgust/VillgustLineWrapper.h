#ifndef VILLGUSTLINEWRAPPER_H
#define VILLGUSTLINEWRAPPER_H


#include "util/TStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TBufStream.h"
#include "util/TThingyTable.h"
#include "util/TLineWrapper.h"
#include <string>
#include <vector>
#include <map>
#include <fstream>

namespace Nes {


class VillgustLineWrapper : public BlackT::TLineWrapper {
public:

  VillgustLineWrapper(BlackT::TStream& src__,
//                  BlackT::TStream& dst__,
                  ResultCollection& dst__,
                  const BlackT::TThingyTable& thingy__,
                  int xSize__ = -1,
                  int ySize__ = -1);
  
  /**
   * Return width of a given symbol ID in "units" --
   * pixels, characters, whatever is compatible with the specified xSize.
   */
  virtual int widthOfKey(int key);
  
  /**
   * Return true if a given symbol ID is considered a word boundary.
   * For English text, this will usually be whitespace characters.
   * Linebreaks can and should be included in this category.
   */
  virtual bool isWordDivider(int key);
  
  /**
   * Return true if a given symbol ID constitutes a linebreak.
   * A linebreak is, by default, considered to do the following:
   *   - increment the yPos
   *   - reset the xPos to zero
   */
  virtual bool isLinebreak(int key);
  
  /**
   * Return true if a given symbol ID constitutes a box clear.
   * A box clear is, by default, considered to do the following:
   *   - reset the xPos to zero
   *   - reset the yPos to zero
   */
  virtual bool isBoxClear(int key);
  
  /**
   * This function is called immediately before the next word would normally
   * be output when the following conditions are met:
   *   a.) yPos == ySize, and
   *   b.) the current word's computed width will, when added to xPos, exceed
   *       xSize (necessitating a linebreak)
   * The implementation should handle this as appropriate for the target,
   * such as by outputting a wait/clear command, emitting an error, etc.
   */
  virtual void onBoxFull();
  
  /**
   * Returns the key of the linebreak symbol.
   */
  virtual int linebreakKey();
  
  virtual void onSymbolAdded(int key);
protected:
  bool waitPending;
};


}


#endif
