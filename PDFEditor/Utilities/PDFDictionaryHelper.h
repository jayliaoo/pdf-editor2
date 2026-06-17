#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFDictionaryHelper : NSObject

+ (NSArray<NSString *> *)allKeysFromDictionary:(CGPDFDictionaryRef)dictionary;

@end

NS_ASSUME_NONNULL_END
