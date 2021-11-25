#import "SyphonServerBase.h"
#import <Metal/MTLPixelFormat.h>
#import <Metal/MTLTexture.h>
#import <Metal/MTLCommandBuffer.h>

NS_ASSUME_NONNULL_BEGIN

@interface SyphonMetalServer : SyphonServerBase

- (id)initWithName:(NSString*)name device:(id<MTLDevice>)device options:(NSDictionary *)options;

// API
- (void)publishFrameTexture:(id<MTLTexture>)textureToPublish imageRegion:(NSRect)region flip:(BOOL)flip;

- (id<MTLTexture>)newFrameImage;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
