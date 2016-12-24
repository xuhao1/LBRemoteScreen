//
//  DJICameraViewController.m
//  FPVDemo
//
//  Created by OliverOu on 2/7/15.
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import "DJICameraViewController.h"
#import <DJISDK/DJISDK.h>
#import <VideoPreviewer/VideoPreviewer.h>
#import "FPVDemo-Swift.h"
@interface DJICameraViewController ()<DJICameraDelegate,DJISDKManagerDelegate, DJIBaseProductDelegate,DJIFlightControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *fpvPreviewView;
@property (assign, nonatomic) BOOL isRecording;
@property (weak, nonatomic) IBOutlet UILabel *RollAngle;
@property (weak, nonatomic) IBOutlet UILabel *PitchAngle;
@property (weak, nonatomic) IBOutlet HUDMapView *HUDMap;
@property (weak, nonatomic) IBOutlet UILabel *Distance2HomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *GroundSpeed;
@property (weak, nonatomic) IBOutlet UILabel *AirLinkLabel;

@end

@implementation DJICameraViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[VideoPreviewer instance] setView:self.fpvPreviewView];
    [self registerApp];
    [_HUDMap initDJIMap];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[VideoPreviewer instance] setView:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Custom Methods
- (DJICamera*) fetchCamera {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }
    
    return nil;
}

- (DJILBAirLink*) fetchLightBridge {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        DJIAirLink * airlink =  ((DJIAircraft*)[DJISDKManager product]).airLink;
        if([airlink isLBAirLinkSupported])
        {
            [_AirLinkLabel setText:@"AirLink : LB2"];
            return airlink.lbAirLink;
        }
        else{
            if([airlink isAuxLinkSupported])
            {
                [_AirLinkLabel setText:@"AirLink : Aux"];
            }
            if([airlink isWifiLinkSupported])
            {
                [_AirLinkLabel setText:@"AirLink : Wifi"];
            }
        }
    }
    
    return nil;
}

- (DJIFlightController*) fetchFlightController {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    return nil;
}

- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)registerApp
{
    NSString *appKey = @"e1617158a2ed990ccd8c9c0d";
    [DJISDKManager registerApp:appKey withDelegate:self];
}

- (NSString *)formattingSeconds:(int)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSString *formattedTimeString = [formatter stringFromDate:date];
    return formattedTimeString;
}

#pragma mark DJISDKManagerDelegate Method

-(void) sdkManagerProductDidChangeFrom:(DJIBaseProduct* _Nullable) oldProduct to:(DJIBaseProduct* _Nullable) newProduct
{
    if (newProduct) {
        
        [newProduct setDelegate:self];
        DJICamera* camera = [self fetchCamera];
        DJIFlightController * fc = [self fetchFlightController];
        DJILBAirLink * lb = [self fetchLightBridge];
        if (camera != nil) {
            camera.delegate = self;
            [_VideoStatusBar setText:@"Video:Waiting for FRAME"];
        }
        else
        {
            if (lb != nil)
            {
                [lb setDelegate:self];
                [_VideoStatusBar setText:@"Video:LB2"];
            }
            else{
                [_VideoStatusBar setText:@"Video:error"];
            }
        }
        if (fc!=nil){
            fc.delegate = self;
            [_StatusBar setText:@"FC:Online"];
        }
        
    }
    else
    {
        [_StatusBar setText:@"FC:Offline"];
        [_VideoStatusBar setText:@"Video:Offline"];
    }
}

- (void)sdkManagerDidRegisterAppWithError:(NSError *)error
{
    NSString* message = @"Register App Successed!";
    if (error) {
        message = @"Register App Failed! Please enter your App Key and check the network.";
        [self showAlertViewWithTitle:@"Register App" withMessage:message];
    }else
    {
        NSLog(@"registerAppSuccess");
        //[DJISDKManager enterDebugModeWithDebugId:@"10.81.10.78"];
        [DJISDKManager startConnectionToProduct];
        [[VideoPreviewer instance] start];
    }
    
    
}

-(void)lbAirLink:(DJILBAirLink *)lbAirLink didReceiveVideoData:(NSData *)data
{
    uint8_t* videoBuffer = [data bytes];
    size_t size = [data length];
    [_VideoStatusBar setText:@"Video:Online"];
    [[VideoPreviewer instance] push:videoBuffer length:(int)size];
}
#pragma mark - DJICameraDelegate
-(void)camera:(DJICamera *)camera didReceiveVideoData:(uint8_t *)videoBuffer length:(size_t)size
{
    [_VideoStatusBar setText:@"Video:Cam Online"];
    [[VideoPreviewer instance] push:videoBuffer length:(int)size];
}


-(void) flightController:(DJIFlightController *)fc didUpdateSystemState:(DJIFlightControllerCurrentState *)state
{
    DJIAttitude  attitude = state.attitude;
    
    
    [_PitchAngle setText: [NSString stringWithFormat:@"%2.1f",attitude.pitch]];
    [_RollAngle setText: [NSString stringWithFormat:@"%2.1f",attitude.roll]];
    [_GroundSpeed setText: [NSString stringWithFormat:@"Vel %2.1f %2.1f",state.velocityX,state.velocityY]];
    [_HUDMap updateAircraftPositionWithLocal:state.aircraftLocation Velx:state.velocityX Vely:state.velocityY yaw:attitude.yaw];
    [_HUDMap updateHomePositionWithLocal:  state.homeLocation];
    CLLocation *homeLocation = [[CLLocation alloc] initWithCoordinate: state.homeLocation altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    CLLocation *aircraftLocation = [[CLLocation alloc] initWithCoordinate:state.aircraftLocation altitude:state.altitude horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];;
    CLLocationDistance distance = [homeLocation distanceFromLocation:aircraftLocation];
    [_Distance2HomeLabel setText:[NSString stringWithFormat:@"%5.0fm",distance]];
    
}
- (IBAction)MapZoomIn:(id)sender {
    _HUDMap.scale = _HUDMap.scale / 1.5;
    NSLog(@"Zoom in");
}
- (IBAction)MapZoomOut:(id)sender {
    _HUDMap.scale = _HUDMap.scale * 1.5;
    NSLog(@"zoom out");
}
@end
