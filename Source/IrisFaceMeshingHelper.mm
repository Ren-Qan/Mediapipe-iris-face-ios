//
//  IrisFaceMeshingHelper.m
//  _idx_FaceEffectAppLibrary_CommonMediaPipeAppLibrary_4073E6E4_ios_min10.0
//
//  Created by 任玉乾 on 2022/1/7.
//

#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPTimestampConverter.h"

#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"
#include "mediapipe/framework/formats/detection.pb.h"

#import "IrisFaceMeshingHelper.h"

static NSString *const kGraphName = @"iris_tracking_gpu";

static const char *kVideoQueueLabel = "com.google.mediapipe.videoQueue";

static const char *kInputStream = "input_video";
static const char *kOutputStream = "output_video";

static const char *kIrisLandmarksOutputStream = "iris_landmarks";
static const char *kFaceLandmarksOutputStream = "face_landmarks";
static const char *kFaceRectsOutputStream = "face_rects_from_landmarks";
static const char *KLeftEyeOutputStream = "left_eye_rect_from_landmarks";
static const char *KRightEyeOutputStream = "right_eye_rect_from_landmarks";
static const char *KFaceDetectionStream = "face_detections";

@interface IrisFaceMeshingHelper () <MPPGraphDelegate, MPPInputSourceDelegate>

@property (nonatomic) MPPGraph *mediapipeGraph;
@property (nonatomic) MPPCameraInputSource *cameraSource;
@property (nonatomic) dispatch_queue_t videoQueue;
@property (nonatomic, assign) BOOL isDidStart;
@property (nonatomic, assign) BOOL graphIsStart;

@end

@implementation IrisFaceMeshingHelper {
    std::map<std::string, mediapipe::Packet> _input_side_packets;
    mediapipe::Packet _focal_length_side_packet;
}

+ (MPPGraph *)loadGraphFromResource:(NSString *)resource {
    NSError *configLoadError = nil;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if (!resource || resource.length == 0) {
        return nil;
    }
    NSURL *graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
    NSData *data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
    if (!data) {
        NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
        return nil;
    }

    mediapipe::CalculatorGraphConfig config;
    config.ParseFromArray(data.bytes, int(data.length));

    MPPGraph *newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
    return newGraph;
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_attr_t qosAttribute = dispatch_queue_attr_make_with_qos_class(
                DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, /*relative_priority=*/0);
        self.videoQueue = dispatch_queue_create(kVideoQueueLabel, qosAttribute);
        
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
        self.mediapipeGraph.delegate = self;
        
        [self.mediapipeGraph addFrameOutputStream:kOutputStream
                                 outputPacketType:MPPPacketTypePixelBuffer];
        [self.mediapipeGraph addFrameOutputStream:kIrisLandmarksOutputStream
                                 outputPacketType:MPPPacketTypeRaw];
        [self.mediapipeGraph addFrameOutputStream:kFaceRectsOutputStream
                                 outputPacketType:MPPPacketTypeRaw];
        [self.mediapipeGraph addFrameOutputStream:kFaceLandmarksOutputStream
                                 outputPacketType:MPPPacketTypeRaw];
        [self.mediapipeGraph addFrameOutputStream:KLeftEyeOutputStream
                                 outputPacketType:MPPPacketTypeRaw];
        [self.mediapipeGraph addFrameOutputStream:KRightEyeOutputStream
                                 outputPacketType:MPPPacketTypeRaw];
        [self.mediapipeGraph addFrameOutputStream:KFaceDetectionStream
                                 outputPacketType:MPPPacketTypeRaw];
        _focal_length_side_packet = mediapipe::MakePacket<std::unique_ptr<float>>(absl::make_unique<float>(0.0));
        _input_side_packets = {
                {"focal_length_pixel", _focal_length_side_packet},
        };
        [self.mediapipeGraph addSidePackets:_input_side_packets];

        self.mediapipeGraph.maxFramesInFlight = 2;
        self.graphIsStart = NO;
    }
    return self;
}

- (void)dealloc {
    self.mediapipeGraph.delegate = nil;
    if (self.cameraSource.isRunning) {
        [self.mediapipeGraph cancel];
        [self.mediapipeGraph closeAllInputStreamsWithError:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.mediapipeGraph waitUntilDoneWithError:nil];
        });
    }
    
    NSLog(@"dealloc");
}

#pragma mark - Public methods

- (BOOL)isCameraInDetection {
    return self.isDidStart;
}

- (void)startCamera {
    if (self.isDidStart) {
        return;
    }
    [self startCameraWithConfig:[CameraSourceConfig.alloc init]];
}

- (void)stopCamera {
    if (self.isDidStart) {
        [self.cameraSource stop];
        self.isDidStart = NO;
    }
}

- (void)startCameraWithConfig:(CameraSourceConfig *)config {
    if (self.isDidStart) {
        return;
    }
    
    self.isDidStart = YES;
    
    CameraSourceConfig *cameraSourceConfig = config;
    if (!cameraSourceConfig) {
        cameraSourceConfig = [[CameraSourceConfig alloc] init];
    }
    
    if (!_cameraSource) {
        self.cameraSource = [[MPPCameraInputSource alloc] init];
        [self.cameraSource setDelegate:self queue:self.videoQueue];
    }
    
    self.cameraSource.sessionPreset = cameraSourceConfig.sessionPreset;
    self.cameraSource.cameraPosition = cameraSourceConfig.cameraPosition;
    self.cameraSource.orientation = cameraSourceConfig.orientation;
    if (cameraSourceConfig.cameraPosition == AVCaptureDevicePositionFront) {
        self.cameraSource.videoMirrored = YES;
    }
    [self.cameraSource requestCameraAccessWithCompletionHandler:^void(BOOL granted) {
        if (granted) {
            self.isDidStart = YES;
            [self startGraphIsWithCamera:YES];
        } else {
            self.isDidStart = NO;
            if ([self.delegate respondsToSelector:@selector(detectionStartFailedWithError:)]) {
                [self.delegate detectionStartFailedWithError:NULL];
            }
        }
    }];
}

- (void)capturePhotoWithSetting:(AVCapturePhotoSettings *)setting {
    [self.cameraSource capturePhotoWithSetting:setting];
}

- (void)withoutCameraAndSendPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (self.isDidStart) {
        return;
    }
    [self startGraphIsWithCamera:NO];
    
    if (self.graphIsStart) {
        dispatch_async(self.videoQueue, ^{
            [self.mediapipeGraph sendPixelBuffer:pixelBuffer
                                      intoStream:kInputStream
                                      packetType:MPPPacketTypePixelBuffer];
        });
    }
}

#pragma mark - MPPInputSourceDelegate

- (void)captureDidFinishWithCapturePhoto:(AVCapturePhoto *)capturePhoto error:(NSError *)error  API_AVAILABLE(ios(11.0)) {
    if ([self.delegate respondsToSelector:@selector(captureDidFinishWithCapturePhoto:error:)]) {
        [self.delegate captureDidFinishWithCapturePhoto:capturePhoto error:error];
    }
}

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer
                timestamp:(CMTime)timestamp
               fromSource:(MPPInputSource *)source {
    if (source != self.cameraSource) {
        NSLog(@"Unknown source: %@", source);
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(cameraFrameWithPixelBuffer:)]) {
        [self.delegate cameraFrameWithPixelBuffer:imageBuffer];
    }

    [self.mediapipeGraph sendPixelBuffer:imageBuffer
                              intoStream:kInputStream
                              packetType:MPPPacketTypePixelBuffer];
}

#pragma mark - MPPGraphDelegate

- (void)mediapipeGraph:(MPPGraph *)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
    if (streamName == kOutputStream) {
        if ([self.delegate respondsToSelector:@selector(mediapipeProcessedFrameWithPixelBuffer:)]) {
            [self.delegate mediapipeProcessedFrameWithPixelBuffer:pixelBuffer];
        }
    }
}

- (void)mediapipeGraph:(MPPGraph *)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
    if (packet.IsEmpty()) {
        return;
    }

    if (streamName == kIrisLandmarksOutputStream) {
        if (![self.delegate respondsToSelector:@selector(didReceiveIrisLandMarks:)]) {
            return;
        }
        [self.delegate didReceiveIrisLandMarks:[self mapLandMarksWithPacket:packet]];
    }
    
    if (streamName == kFaceLandmarksOutputStream) {
        if (![self.delegate respondsToSelector:@selector(didReceiveFaceLandMarks:)]) {
            return;
        }
        [self.delegate didReceiveFaceLandMarks:[self mapLandMarksWithPacket:packet]];
    }
    
    if (streamName == kFaceRectsOutputStream) {
        if (![self.delegate respondsToSelector:@selector(didReceiveFaceNormalizedRect:)]) {
            return;
        }
        [self.delegate didReceiveFaceNormalizedRect:[self mapNormalizedRecWithPacket:packet isList:YES]];
    }
    
    if (streamName == KLeftEyeOutputStream) {
        if (![self.delegate respondsToSelector:@selector(didReceiveLeftEyeRect:)]) {
            return;
        }
        [self.delegate didReceiveLeftEyeRect:[self mapNormalizedRecWithPacket:packet isList:NO]];
    }
    
    if (streamName == KRightEyeOutputStream) {
        if (![self.delegate respondsToSelector:@selector(didReceiveRightEyeRect:)]) {
            return;
        }
        [self.delegate didReceiveRightEyeRect:[self mapNormalizedRecWithPacket:packet isList:NO]];
    }
    
    if (streamName == KFaceDetectionStream) {
        if (![self.delegate respondsToSelector:@selector(didReceiveFeceDecetionScore:)]) {
            return;
        }
        [self.delegate didReceiveFeceDecetionScore:[self mapScoreWithPacket:packet]];
    }
}

#pragma mark - Private methods

- (void)startGraphIsWithCamera:(BOOL)isWithCamera {
    NSError *error;
    if (!self.graphIsStart)  {
        if (![self.mediapipeGraph startWithError:&error]) {
            NSLog(@"Failed to start graph: %@", error);
        } else if (![self.mediapipeGraph waitUntilIdleWithError:&error]) {
            NSLog(@"Failed to complete graph initial run: %@", error);
        }
    }
    
    if (!error) {
        self.graphIsStart = YES;
        if ([self.delegate respondsToSelector:@selector(detectionStartSuccess)]) {
            [self.delegate detectionStartSuccess];
        }
        if (isWithCamera) {
            dispatch_async(self.videoQueue, ^{
                [self.cameraSource start];
            });
        }
    } else {
        self.isDidStart = NO;
        self.graphIsStart = NO;
        if ([self.delegate respondsToSelector:@selector(detectionStartFailedWithError:)]) {
            [self.delegate detectionStartFailedWithError:error];
        }
    }
}

- (NSArray <LandmarkPointModel *> *)mapLandMarksWithPacket:(const ::mediapipe::Packet&)packet {
    const auto &landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
    NSMutableArray<LandmarkPointModel *> *resultLandMarks = [NSMutableArray array];
    for (int i = 0; i < landmarks.landmark_size(); ++i) {
        float x = landmarks.landmark(i).x();
        float y = landmarks.landmark(i).y();
        float z = landmarks.landmark(i).z();
        LandmarkPointModel *model = [[LandmarkPointModel alloc] init];
        model.x = x;
        model.y = y;
        model.z = z;
        [resultLandMarks addObject:model];
    }
    if (resultLandMarks.count > 0) {
        return resultLandMarks;
    }
    return NULL;
}

- (NormalizedRectModel *)mapNormalizedRecWithPacket:(const ::mediapipe::Packet&)packet isList:(BOOL)isList {
    if (isList) {
        const auto &rects = packet.Get<std::vector<::mediapipe::NormalizedRect>>();
        for (int i = 0; i < rects.size(); i++) {
            const auto& face = rects[i];
            return [self rectWithRectFromLandMark:face];
        }
        return  NULL;
    }
    return [self rectWithRectFromLandMark:packet.Get<::mediapipe::NormalizedRect>()];
}

- (NormalizedRectModel *)rectWithRectFromLandMark:(const ::mediapipe::NormalizedRect&)rectFromLandMark {
    float centerX = rectFromLandMark.x_center();
    float centerY = rectFromLandMark.y_center();
    float height = rectFromLandMark.height();
    float width = rectFromLandMark.width();
    float rotation = rectFromLandMark.rotation();
    
    NormalizedRectModel *rect = [[NormalizedRectModel alloc] init];
    rect.centerX = centerX;
    rect.centerY = centerY;
    rect.height = height;
    rect.width = width;
    rect.rotation = rotation;
    return rect;
}

- (NSNumber *)mapScoreWithPacket:(const ::mediapipe::Packet&)packet {
    const auto& decetions = packet.Get<std::vector<mediapipe::Detection>>();
    for (int i = 0; i < decetions.size(); i++) {
        float scroe = decetions[i].score(0);
        return [[NSNumber alloc] initWithFloat:scroe];
    }
    return NULL;
}

@end

@implementation CameraSourceConfig

- (instancetype)init {
    if (self = [super init]) {
        _cameraPosition = AVCaptureDevicePositionFront;
        _orientation = AVCaptureVideoOrientationPortrait;
        _sessionPreset = AVCaptureSessionPresetHigh;
    }
    return self;
}

@end

@implementation LandmarkPointModel
@end

@implementation NormalizedRectModel

- (CGRect)convertWithFrame:(CGRect)frame scale:(CGFloat)scale; {
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    
    CGFloat width = w * self.width * scale;
    CGFloat height = h * self.height * scale;
    
    CGFloat x = w * CGFloat(self.centerX) - width * 0.5 + frame.origin.x;
    CGFloat y = h * CGFloat(self.centerY) - height * 0.5 + frame.origin.y;
    return  CGRectMake(x, y, width, height);
}

@end
