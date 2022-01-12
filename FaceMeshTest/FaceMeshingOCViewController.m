//
//  FaceMeshingOCViewController.m
//  FaceMeshTest
//
//  Created by 任玉乾 on 2022/1/12.
//

#import "FaceMeshingOCViewController.h"
#import "FaceMeshing.framework/Headers/IrisFaceMeshingHelper.h"


@interface FaceMeshingOCViewController () <IrisFaceMeshingHelperDelegate>

@property (nonatomic, strong) IrisFaceMeshingHelper *helper;

@property (nonatomic, strong) UIImageView *originalImageView;

@property (nonatomic, strong) UIImageView *mediapipeImageView;

@end

@implementation FaceMeshingOCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:UIColor.whiteColor];
    _helper = [[IrisFaceMeshingHelper alloc] init];
    _helper.delegate = self;
    
    CGFloat KW = UIScreen.mainScreen.bounds.size.width;
    CGFloat KH = UIScreen.mainScreen.bounds.size.height;
    
    CGFloat viewW = KW * 0.5 - 25;
    CGFloat viewH = viewW * KH / KW;
    
    _originalImageView = [[UIImageView alloc] init];
    _originalImageView.layer.masksToBounds = YES;
    _originalImageView.contentMode = UIViewContentModeScaleAspectFill;
    _originalImageView.frame = CGRectMake(20, 160, viewW, viewH);
    
    _mediapipeImageView = [[UIImageView alloc] init];
    _mediapipeImageView.layer.masksToBounds = YES;
    _mediapipeImageView.contentMode = UIViewContentModeScaleAspectFill;
    _mediapipeImageView.frame = CGRectMake(KW * 0.5 + 5, 160, viewW, viewH);
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
    [btn setTitle:@"start" forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_originalImageView];
    [self.view addSubview:_mediapipeImageView];
    [self.view addSubview:btn];
}

- (void)start {
    [_helper startCamera];
}

- (void)mediapipeProcessedFrameWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    UIImage *image = [self.class convert:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mediapipeImageView.image = image;
    });
}

- (void)cameraFrameWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    UIImage *image = [self.class convert:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.originalImageView.image = image;
    });
}


+ (UIImage *)convert:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    if (!ciImage) {
        return NULL;
    }
        
    CGRect bounds = CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:bounds];
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);

    return uiImage;
}

@end
