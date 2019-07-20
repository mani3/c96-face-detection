//
//  TFLite.m
//  FaceDetection
//
//  Created by kazuya.shida on 2019/07/13.
//  Copyright © 2019 mani3. All rights reserved.
//

#import "TFLite.h"
#import <UIKit/UIKit.h>

#include "tensorflow/lite/model.h"
#include "tensorflow/lite/kernels/register.h"
#include "tensorflow/lite/string_util.h"

@interface TFLite() {
  std::unique_ptr<tflite::FlatBufferModel> model;
  tflite::ops::builtin::BuiltinOpResolver resolver;
  std::unique_ptr<tflite::Interpreter> interpreter;
}

@end

@implementation TFLite

- (instancetype) initWithFileName:(nonnull NSString *) filename {
  self = [super init];
  if (self) {
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType: @"tflite"];
    if (!path) {
      NSLog(@"%@ is not found", filename);
      return self;
    }
    
    model = tflite::FlatBufferModel::BuildFromFile([path UTF8String]);
    if (!model) {
      NSLog(@"Failed to load model %@", filename);
    }
    
    tflite::InterpreterBuilder(*model, resolver)(&interpreter);
    if (!interpreter) {
      NSLog(@"Failed to build interpreter");
    }
    if (interpreter->AllocateTensors() != kTfLiteOk) {
      NSLog(@"Failed to allocate tensors on interpreter");
    }
  }
  return self;
}

- (uint8_t *)inputTensorAtIndex:(int) index {
  int input = interpreter->inputs()[index];
  uint8_t* output = interpreter->typed_tensor<uint8_t>(input);
  return output;
}

- (BOOL) invokeInterpreter {
  if (interpreter->Invoke() != kTfLiteOk) {
    NSLog(@"Failed to invoke!");
    return false;
  }
  return true;
}

- (float *) outputTensorAtIndex:(int) index {
  return interpreter->typed_output_tensor<float>(index);
}

@end
