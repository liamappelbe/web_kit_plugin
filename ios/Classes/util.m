#import <Foundation/NSObject.h>

#include "../../src/WebKitPlugin.h"

NSObject* intToObject(int64_t raw_pointer) {
  return (NSObject*)raw_pointer;
}

// HACK: I want to call intToObject from Swift, but all the documentation about
// calling ObjC from Swift assumes you're working on a self contained project in
// Xcode. So I'm not sure how to create the bridging header in a flutter plugin.
// Since I can call from ObjC into Swift using the generated ObjC header,
// WebKitPlugin.h, my workaround is to pass a closure to Swift which invokes
// intToObject. setupUtil is invoked from Dart using FFI. A flutter+iOS expert
// can probably clean this up and get Swift to call intToObject directly.
void setupUtil() {
  [WebKitViewWrapper setIntToObject: [^NSObject*(int64_t raw_pointer) {
    return intToObject(raw_pointer);
  } copy]];
}
