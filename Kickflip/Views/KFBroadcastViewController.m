//
//  KFBroadcastViewController.m
//  Encoder Demo
//
//  Created by Geraint Davies on 11/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "KFBroadcastViewController.h"
#import "KFRecorder.h"
#import "KFAPIClient.h"
#import "KFUser.h"
#import "KFLog.h"
#import "PureLayout.h"

@implementation KFBroadcastViewController

- (id) init {
    if (self = [super init]) {
        self.recorder = [[KFRecorder alloc] init];
        self.recorder.delegate = self;
    }
    return self;
}

- (void) setupCameraView {
    _cameraView = [[UIView alloc] init];
    _cameraView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_cameraView];
}

/*
- (void) setupShareButton {
    _shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
    [_shareButton setTitle:@"Buffering..." forState:UIControlStateDisabled];
    self.shareButton.enabled = NO;
    self.shareButton.alpha = 0.0f;
    self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.shareButton];
    NSLayoutConstraint *constraint = [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10.0f];
    [self.view addConstraint:constraint];
    constraint = [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10.0f];
    [self.view addConstraint:constraint];
}*/

- (void) setupRecordButton {
    self.recordButton = [[KFRecordButton alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.recordButton];
    [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // recordButtonの位置を変更
    NSLayoutConstraint *leftConstraint = [self.recordButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10.0f];
    NSLayoutConstraint *bottomConstraint = [self.recordButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0f];
    [self.view addConstraint:leftConstraint];
    [self.view addConstraint:bottomConstraint];
    NSLayoutConstraint *verticalConstraint = [self.recordButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.view addConstraint:verticalConstraint];
    
}

- (void) setupCancelButton {
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelButton];
    
    NSLayoutConstraint *constraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0f];
    [self.view addConstraint:constraint];
    constraint = [self.cancelButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10.0f];
    [self.view addConstraint:constraint];
}


- (void) cancelButtonPressed:(id)sender {
    if (_completionBlock) {
        _completionBlock(YES, nil);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void) recordButtonPressed:(id)sender {
    self.recordButton.enabled = NO;
    self.cancelButton.enabled = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.cancelButton.alpha = 0.0f;
    }];
    if (!self.recorder.isRecording) {
        [self.recorder startRecording];
    } else {
        [self.recorder stopRecording];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupCameraView];
//    [self setupShareButton];
    [self setupRecordButton];
    [self setupCancelButton];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    _cameraView.frame = self.view.bounds;
    
    //[self checkViewOrientation:animated];
    
    [self startPreview];
}


- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // this is not the most beautiful animation...
    AVCaptureVideoPreviewLayer* preview = self.recorder.previewLayer;
    [UIView animateWithDuration:duration animations:^{
        preview.frame = self.cameraView.bounds;
    } completion:NULL];
    [[preview connection] setVideoOrientation:[self avOrientationForInterfaceOrientation:toInterfaceOrientation]];
    
    [self checkViewOrientation:YES];
}

- (void) checkViewOrientation:(BOOL)animated {
    CGFloat duration = 0.2f;
    if (!animated) {
        duration = 0.0f;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // Hide controls in Portrait
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortrait) {
        self.recordButton.enabled = NO;
        [UIView animateWithDuration:0.2 animations:^{
            //self.shareButton.alpha = 0.0f;
            self.recordButton.alpha = 0.0f;
            self.rotationLabel.alpha = 1.0f;
            //self.rotationImageView.alpha = 1.0f;
        } completion:NULL];
    } else {
        self.recordButton.enabled = YES;
        [UIView animateWithDuration:0.2 animations:^{
            if (self.recorder.isRecording) {
                //self.shareButton.alpha = 1.0f;
            }
            self.recordButton.alpha = 1.0f;
            self.rotationLabel.alpha = 0.0f;
            //self.rotationImageView.alpha = 0.0f;
        } completion:NULL];
    }
}

- (AVCaptureVideoOrientation) avOrientationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
    }
}

- (void) startPreview
{
    AVCaptureVideoPreviewLayer* preview = self.recorder.previewLayer;
    [preview removeFromSuperlayer];
    preview.frame = self.cameraView.bounds;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    [[preview connection] setVideoOrientation:[self avOrientationForInterfaceOrientation:orientation]];
    
    [self.cameraView.layer addSublayer:preview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) recorderDidStartRecording:(KFRecorder *)recorder error:(NSError *)error {
    self.recordButton.enabled = YES;
    if (error) {
        DDLogError(@"Error starting stream: %@", error.userInfo);
        NSDictionary *response = [error.userInfo objectForKey:@"response"];
        NSString *reason = nil;
        if (response) {
            reason = [response objectForKey:@"reason"];
        }
        NSMutableString *errorMsg = [NSMutableString stringWithFormat:@"Error starting stream: %@.", error.localizedDescription];
        if (reason) {
            [errorMsg appendFormat:@" %@", reason];
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Start Error" message:errorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        self.recordButton.isRecording = NO;
    } else {
        self.recordButton.isRecording = YES;
        //self.shareButton.alpha = 1.0f;
    }
}

- (void) recorder:(KFRecorder *)recorder streamReadyAtURL:(NSURL *)url {
    //self.shareButton.enabled = YES;
    if (_readyBlock) {
        _readyBlock(recorder.stream);
    }
}

- (void) recorderDidFinishRecording:(KFRecorder *)recorder error:(NSError *)error {
    if (_completionBlock) {
        if (error) {
            _completionBlock(NO, error);
        } else {
            _completionBlock(YES, nil);
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
