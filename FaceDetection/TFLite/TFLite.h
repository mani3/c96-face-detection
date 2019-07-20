//
//  TFLite.h
//  FaceDetection
//
//  Created by kazuya.shida on 2019/07/13.
//  Copyright © 2019 mani3. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFLite : NSObject

- (instancetype) initWithFileName:(nonnull NSString *) filename;
- (uint8_t *)inputTensorAtIndex:(int) index;
- (BOOL) invokeInterpreter;
- (float *) outputTensorAtIndex:(int) index;

@end

NS_ASSUME_NONNULL_END
