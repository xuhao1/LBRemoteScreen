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
#include "key_input.h"
#include "keyboard_mouse_event.h"

@interface DJICameraViewController ()<DJICameraDelegate,DJISDKManagerDelegate, DJIBaseProductDelegate,DJIFlightControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *fcstatuslabel;

@property (weak, nonatomic) IBOutlet UIView *fpvPreviewView;
@property (assign, nonatomic) BOOL isRecording;
@property (weak, nonatomic) IBOutlet UILabel *AirLinkLabel;
@property (weak, nonatomic) IBOutlet UILabel *inputTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *touchTextLabel;
@property (weak, nonatomic) IBOutlet UITextView *externldatalabel;
@property NSData * nsdata_send_buffer;
@end

@implementation DJICameraViewController

NSMutableString *textInput;   //keyboard input for send
struct TOUCH_DATA touchData;  //touch commands for send
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[VideoPreviewer instance] setView:self.fpvPreviewView];
    [self registerApp];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[VideoPreviewer instance] setView:nil];
}

- (void)viewDidLoad {
    
    [UIApplication sharedApplication].idleTimerDisabled =YES;
    
    textInput = [NSMutableString string];
    
    //single finger or double finger drag
    UIPanGestureRecognizer *resultPanGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                          initWithTarget:self
                                                          action:@selector(handlePan:)];
    resultPanGestureRecognizer.minimumNumberOfTouches = 1;
    resultPanGestureRecognizer.maximumNumberOfTouches = 2;
    [self.fpvPreviewView addGestureRecognizer:resultPanGestureRecognizer];
    
    //singer finger tap
    UITapGestureRecognizer *resultTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                          initWithTarget:self
                                                          action:@selector(handleTap:)];
    resultTapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.fpvPreviewView addGestureRecognizer:resultTapGestureRecognizer];
    //double finger tap
    UITapGestureRecognizer *resultTapGestureRecognizer2 = [[UITapGestureRecognizer alloc]
                                                          initWithTarget:self
                                                          action:@selector(handleTapDouble:)];
    resultTapGestureRecognizer2.numberOfTouchesRequired = 2	;
    [self.fpvPreviewView addGestureRecognizer:resultTapGestureRecognizer2];
    
    //two fingers zoom in/out
    UIPinchGestureRecognizer *resultPinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                                          initWithTarget:self
                                                          action:@selector(handlePinch:)];
    [self.fpvPreviewView addGestureRecognizer:resultPinchGestureRecognizer];
    
    //single finger long pressed
    UILongPressGestureRecognizer *resultLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                                          initWithTarget:self
                                                          action:@selector(handleLongPress:)];
    [self.fpvPreviewView addGestureRecognizer:resultLongPressGestureRecognizer];
    
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
            [_fcstatuslabel setText:@"FC:Online"];
            NSLog(@"FC ONLINE!!!");
            [_touchTextLabel setText: @"FC:Online"];
            
        }
        else{
            NSLog(@"FC OFFFLINE");
        }
        
    }
    else
    {
        [_fcstatuslabel setText:@"FC:Offline"];
        [_VideoStatusBar setText:@"Video:Offline"];
        [_touchTextLabel setText: @"FC:Offline"];
        
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
        //[DJISDKManager enterDebugModeWithDebugId:@"192.168.1.161"];
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
    //[self sendData:@"Hello,world!!!"];
}






- (void) flightController:(DJIFlightController *)fc didReceiveDataFromExternalDevice:(NSData *)data
{
    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //[_externldatalabel setText:newStr];
}
/***********************************************************UI KeyBoard***************************************************/

bool shift_on_press = false;
bool ctrl_on_press = false;
bool alt_on_press = false;


- (void)showInputView
{
    @autoreleasepool
    {
        [_inputTextLabel setText:textInput];
    }
    
}
- (IBAction)ctrl_pressed:(id)sender {
    ctrl_on_press = true;
}
- (IBAction)alt_release:(id)sender {
    alt_on_press = false;
}
- (IBAction)alt_pressed:(id)sender {
    alt_on_press = true;
}

- (IBAction)ctrl_release:(id)sender {
    ctrl_on_press = false;
}
//switch key
- (IBAction)shiftPressed:(id)sender {
    NSLog(@"Touch shift");
    shift_on_press = true;
}
- (IBAction)shift_release:(id)sender {
    NSLog(@"release shift");
    shift_on_press = false;
}
- (IBAction)backSpacePressed:(id)sender {
    
    NSUInteger i = [textInput length];
    if(i == 0)
        return;
    [textInput deleteCharactersInRange:NSMakeRange(i-1, 1)];
    [self performSelectorOnMainThread:@selector(showInputView) withObject:nil waitUntilDone:YES];
    [self press_key:KEY_BACKSPACE];
}

// text input key
- (IBAction)keyTextPressed:(id)sender {
    
    UIButton *button=(UIButton*)sender;
    NSString *buttonText = [button titleForState:UIControlStateNormal];
    
    unichar firstChar = [[buttonText uppercaseString] characterAtIndex:0];
    uint8_t output;
    
    output = firstChar;
   
    UIImage *btnImage2 = [UIImage imageNamed:@"back.png"];
    [_shiftButton setBackgroundImage:btnImage2 forState:UIControlStateNormal];
    [_shiftRightButton setBackgroundImage:btnImage2 forState:UIControlStateNormal];
    
    NSLog(@"%c",output);
    
    [textInput appendFormat:@"%c",output];
    [self press_key:alpha_bet_events[output - 'A']];
    [self performSelectorOnMainThread:@selector(showInputView) withObject:nil waitUntilDone:YES];
}
- (IBAction)SpacePress:(id)sender {
    [self press_key:KEY_SPACE];
}

//function key
- (IBAction)functionKeyPressed:(id)sender {
    
    UIButton *button=(UIButton*)sender;
    NSString *buttonText = [button titleForState:UIControlStateNormal];
    NSLog(@"%@",buttonText);
    
    if([buttonText isEqualToString:@"Enter"])
    {
        //TODO : send text in textInput
        
        //then delete them
        [textInput deleteCharactersInRange:NSMakeRange(0, [textInput length])];
    }
    [self performSelectorOnMainThread:@selector(showInputView) withObject:nil waitUntilDone:YES];
    
    //TODO : send command
}

/*************************************************************UI TouchScreen*******************************************************/
- (void) handlePan:(UIPanGestureRecognizer*) recognizer
{
    CGRect imageViewRect = [self.fpvPreviewView frame];
    NSUInteger height = imageViewRect.size.height;
    NSUInteger width = imageViewRect.size.width;
    
    CGPoint translation = [recognizer locationInView:self.view];
    NSUInteger numberTouch = [recognizer numberOfTouches];
    
    //for display
    CGRect origionRect = _touchTextLabel.frame;
    CGRect newRect = CGRectMake(translation.x, translation.y - 20, origionRect.size.width, origionRect.size.height);
    _touchTextLabel.frame = newRect;
    
    
    //for send
    float xNorm = translation.x/width;
    float yNorm = translation.y/height;
    
    if(numberTouch == 1)
    {
        touchData.type = SINGLE_DRAG;
        touchData.location = CGPointMake(xNorm, yNorm);
        NSLog(@"single finger drag:(%f,%f)",xNorm,yNorm);
        [_touchTextLabel setText: @"Single drag"];
        struct key_mouse_event event;
        mouse_move_to_event(&event, xNorm * SCREEN_WITDH, yNorm*SCREEN_HEIGHT);
        [self send_key_mouse_event:&event];
    }
    else if(numberTouch == 2)
    {
        touchData.type = DOUBLE_DRAG;
        touchData.location = CGPointMake(xNorm, yNorm);
        NSLog(@"double fingers drag:(%f,%f)",xNorm,yNorm);
        [_touchTextLabel setText: @"Double drag"];
    }
    //TODO send touchData
}
- (IBAction)EnterPress:(id)sender {
    [self press_key:KEY_ENTER];
}

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    CGRect imageViewRect = [self.fpvPreviewView frame];
    NSUInteger height = imageViewRect.size.height;
    NSUInteger width = imageViewRect.size.width;
    
    CGPoint translation = [recognizer locationInView:self.view];
    
    //for display
    CGRect origionRect = _touchTextLabel.frame;
    CGRect newRect = CGRectMake(translation.x, translation.y - 20, origionRect.size.width, origionRect.size.height);
    _touchTextLabel.frame = newRect;
    [_touchTextLabel setText: @"Tap"];
    
    float xNorm = translation.x/width;
    float yNorm = translation.y/height;
    
    touchData.type = TAP;
    touchData.location = CGPointMake(xNorm, yNorm);
    
    NSLog(@"single finger tap:(%f,%f)",xNorm,yNorm);
    //TODO send touchData
    struct key_mouse_event event;
    mouse_press_to_event(&event, xNorm * SCREEN_WITDH, yNorm*SCREEN_HEIGHT,BTN_LEFT);
    [self send_key_mouse_event:&event];
}


- (void) handleTapDouble:(UITapGestureRecognizer*)recognizer
{
    CGRect imageViewRect = [self.fpvPreviewView frame];
    NSUInteger height = imageViewRect.size.height;
    NSUInteger width = imageViewRect.size.width;
    
    CGPoint translation = [recognizer locationInView:self.view];
    
    //for display
    CGRect origionRect = _touchTextLabel.frame;
    CGRect newRect = CGRectMake(translation.x, translation.y - 20, origionRect.size.width, origionRect.size.height);
    _touchTextLabel.frame = newRect;
    [_touchTextLabel setText: @"DoubleTap"];
    
    float xNorm = translation.x/width;
    float yNorm = translation.y/height;
    
    touchData.type = TAP;
    touchData.location = CGPointMake(xNorm, yNorm);
    
    NSLog(@"single finger tap:(%f,%f)",xNorm,yNorm);
    //TODO send touchData
    struct key_mouse_event event;
    mouse_press_to_event(&event, xNorm * SCREEN_WITDH, yNorm*SCREEN_HEIGHT,BTN_RIGHT);
    [self send_key_mouse_event:&event];
}

- (void) handlePinch:(UIPinchGestureRecognizer*) recognizer
{
    CGRect imageViewRect = [self.fpvPreviewView frame];
    NSUInteger height = imageViewRect.size.height;
    NSUInteger width = imageViewRect.size.width;
    
    CGPoint translation = [recognizer locationInView:self.view];
    float factor = recognizer.scale;
    
    //for display
    CGRect origionRect = _touchTextLabel.frame;
    CGRect newRect = CGRectMake(translation.x, translation.y - 20, origionRect.size.width, origionRect.size.height);
    _touchTextLabel.frame = newRect;
    NSString *string = [NSString stringWithFormat:@"Zoom by %.2f",factor];
    [_touchTextLabel setText:string];
    
    float xNorm = translation.x/width;
    float yNorm = translation.y/height;
    
    touchData.type = ZOOM;
    touchData.location = CGPointMake(xNorm, yNorm);
    touchData.factor = factor;
    
    NSLog(@"zoom in:(%f,%f) by %f",xNorm,yNorm,factor);
    //TODO send touchData
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
    CGRect imageViewRect = [self.fpvPreviewView frame];
    NSUInteger height = imageViewRect.size.height;
    NSUInteger width = imageViewRect.size.width;
    
    CGPoint translation = [recognizer locationInView:self.view];
    
    //for display
    CGRect origionRect = _touchTextLabel.frame;
    CGRect newRect = CGRectMake(translation.x, translation.y - 20, origionRect.size.width, origionRect.size.height);
    _touchTextLabel.frame = newRect;
    [_touchTextLabel setText: @"Long press"];
    
    float xNorm = translation.x/width;
    float yNorm = translation.y/height;
    
    NSLog(@"long press:(%f,%f)",xNorm,yNorm);
    //TODO send touchData
}
- (void) sendData:(NSString*) data
{
    DJIFlightController *fc = [self fetchFlightController];
    if(fc)
    {
        [fc sendDataToOnboardSDKDevice:[data dataUsingEncoding:NSUTF8StringEncoding] withCompletion:nil];
    }
}

- (void) sendData:(uint8_t*) data with: (int) len
{
    DJIFlightController *fc = [self fetchFlightController];
    if(fc)
    {			
        NSLog(@"FC Online,send data 2 mobile with len %d",len);
        _nsdata_send_buffer = [NSData dataWithBytes:data length:len];
        for ( int i =0 ; i < len ;i ++ )
        {
            NSLog(@"%d",((uint8_t*)_nsdata_send_buffer.bytes)[i]);
        }
        [fc sendDataToOnboardSDKDevice:_nsdata_send_buffer withCompletion:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error");
            } else {
                NSLog(@"success");
            }
        }];
        NSLog(@"send finished");
    }
    else{
        NSLog(@"FC offline!!!");
    }
    
}
- (void) press_key:(int) key
{
    int keys[MAX_COMBO_KEY] = {0};
    int key_count  = 0;
    for (int i = 0; i< MAX_COMBO_KEY;i++)
    {
        keys[i] = -1;
    }
    
    if(shift_on_press)
    {
        keys[key_count] = KEY_LEFTSHIFT;
        key_count ++;
        
    }
    if (ctrl_on_press)
    {
        keys[key_count] = KEY_LEFTCTRL;
        key_count ++;
    }
    if(alt_on_press)
    {
        keys[key_count] = KEY_LEFTALT;
        key_count ++;
        
    }
    keys[key_count] = key;
    
    [self send_key_events:keys];
    
        
}

- (void) send_key_events:(int*) keys
{
    struct key_mouse_event event;
    keyboard_to_event(&event, keys);
    [self send_key_mouse_event:&event];
}
-(void) send_key_mouse_event:(struct key_mouse_event *) event
{
    static uint8_t msg[256] = {0};
    memset(msg,0,256*sizeof(uint8_t));
    int len = key_mouse_event_to_msg(msg, event);
    [self sendData:msg with:len];
    
}
@end
