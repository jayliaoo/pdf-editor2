#import "PDFDictionaryHelper.h"

// C 回调函数
static void dictionaryApplierCallback(const char *key, CGPDFObjectRef object, void *info) {
    NSMutableArray<NSString *> *keysArray = (__bridge NSMutableArray *)info;
    NSString *keyString = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    if (keyString) {
        [keysArray addObject:keyString];
    }
}

@implementation PDFDictionaryHelper

+ (NSArray<NSString *> *)allKeysFromDictionary:(CGPDFDictionaryRef)dictionary {
    if (!dictionary) {
        return @[];
    }

    NSMutableArray<NSString *> *keys = [NSMutableArray array];

    CGPDFDictionaryApplyFunction(dictionary, dictionaryApplierCallback, (__bridge void *)keys);

    return [keys copy];
}

@end
