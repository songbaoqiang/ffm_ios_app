#import <Foundation/Foundation.h>

#include "mupdf/fitz.h"

@interface MuDocRef : NSObject
{
@public
	fz_document *doc;
	bool interactive;
}
-(id) initWithFilename:(const char *)aFilename;
@end
