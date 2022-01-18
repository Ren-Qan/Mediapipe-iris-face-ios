//
//  IrisFaceMeshingHelper.h
//  _idx_FaceEffectAppLibrary_CommonMediaPipeAppLibrary_4073E6E4_ios_min10.0
//
//  Created by 任玉乾 on 2022/1/7.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IrisFaceMeshingHelper;
@class CameraSourceConfig;
@class LandmarkPointModel;
@class NormalizedRectModel;

@protocol IrisFaceMeshingHelperDelegate <NSObject>

@optional

- (void)detectionStartSuccess;

- (void)detectionStartFailedWithError:(nullable NSError *)error;

/// 返回面部的Frame 其中 x,y,w,h 都是0-1的相对坐标
/// @param faceRect NormalizedRectModel
- (void)didReceiveFaceNormalizedRect:(nullable NormalizedRectModel *)faceRect;

/// 面部的特征点，若是有数据则固定长度为468
/// 左上眼皮特征点下标 : [249, 390, 373, 374, 380, 381, 382]
/// 左下眼皮特征点下标 : [466, 388, 387, 386, 385, 384, 398]
/// 右上眼皮特征点下标 : [7, 163, 144, 145, 153, 154, 155]
/// 右下眼皮特征点下标 : [246, 161, 160, 159, 158, 157, 173]
/// 参照 https://github.com/google/mediapipe/blob/master/mediapipe/java/com/google/mediapipe/solutions/facemesh/FaceMeshConnections.java
/// @param faceLandMarks LandmarkPointModel
- (void)didReceiveFaceLandMarks:(nullable NSArray<LandmarkPointModel *> *)faceLandMarks;

/// 虹膜的特征点，如果有数据则固定长度为10
/// @param irisLandMarks LandmarkPointModel
- (void)didReceiveIrisLandMarks:(nullable NSArray<LandmarkPointModel *> *)irisLandMarks;

/// 左眼的区域范围，整个左眼的范围（建议调试观察不要直接用，并不只是眼睛的范围）
/// @param eyeRect NormalizedRectModel
- (void)didReceiveLeftEyeRect:(nullable NormalizedRectModel *)eyeRect;

/// 右眼的区域范围，整个右眼的范围（建议调试观察不要直接用，并不只是眼睛的范围）
/// @param eyeRect NormalizedRectModel
- (void)didReceiveRightEyeRect:(nullable NormalizedRectModel *)eyeRect;

/// 人脸检测的分数 0-100 不是一直返回，当需要检测的时候才会返回分数（建议调试使用）
/// @param score float
- (void)didReceiveFeceDecetionScore:(nullable NSNumber *)score;

/// 相机采集到的数据
/// @param pixelBuffer CVPixelBufferRef
- (void)cameraFrameWithPixelBuffer:(nullable CVPixelBufferRef)pixelBuffer;

/// mediapipe处理过后的数据
/// @param pixelBuffer CVPixelBufferRef
- (void)mediapipeProcessedFrameWithPixelBuffer:(nullable CVPixelBufferRef)pixelBuffer;

/// 拍照后的回调
/// @param capturePhoto AVCapturePhoto
/// @param error NSError
- (void)captureDidFinishWithCapturePhoto:(nullable AVCapturePhoto *)capturePhoto error:(nullable NSError *)error API_AVAILABLE(ios(11.0));
@end

@interface IrisFaceMeshingHelper : NSObject

@property(weak, nonatomic) id <IrisFaceMeshingHelperDelegate> delegate;

- (BOOL)isCameraInDetection;

- (void)startCamera;

- (void)stopCamera;

- (void)startCameraWithConfig:(CameraSourceConfig *)config;

- (void)capturePhotoWithSetting:(AVCapturePhotoSettings *)setting;

- (void)withoutCameraAndSendPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface LandmarkPointModel : NSObject

@property (nonatomic) float x;

@property (nonatomic) float y;

@property (nonatomic) float z;

@end

@interface NormalizedRectModel : NSObject

@property (nonatomic) float centerX;

@property (nonatomic) float centerY;

@property (nonatomic) float height;

@property (nonatomic) float width;

@property (nonatomic) float rotation;

/// 转换为相对于承载相机View的内部坐标
/// @param frame 承载相机View的Frame
/// @param scale 缩放(width，height)的比例 （建议调试然后拿最合适的参数）
- (CGRect)convertWithFrame:(CGRect)frame scale:(CGFloat)scale;

@end

@interface CameraSourceConfig : NSObject

@property(nonatomic) AVCaptureDevicePosition cameraPosition;

@property(nonatomic) AVCaptureVideoOrientation orientation;

@property(nonatomic) AVCaptureSessionPreset sessionPreset;

@end

NS_ASSUME_NONNULL_END
