@import Cocoa;

@class CUIRenditionSliceInformation;
@interface CUIRenditionKey : NSObject <NSCopying, NSCoding>
@end

@interface CUIThemeRendition : NSObject
- (nullable CGImageRef)unslicedImage;
@end

@interface CUINamedLookup : NSObject
- (nonnull CUIThemeRendition *)_rendition;
@end

@interface CUINamedImage : CUINamedLookup
@end

@interface CUICatalog : NSObject
- (nullable instancetype)initWithURL:(nonnull NSURL *)url error:(NSError *_Nullable __autoreleasing *_Nullable)error;
- (nonnull NSArray<NSString *> *)allImageNames;
- (nonnull NSArray<id> *)imagesWithName:(nonnull NSString *)name;
@end
