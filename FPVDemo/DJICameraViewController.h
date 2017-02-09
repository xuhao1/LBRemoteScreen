//
//  DJICameraViewController.h
//  FPVDemo
//
//  Created by OliverOu on 2/7/15.
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DJICameraViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *VideoStatusBar;
@property (weak, nonatomic) IBOutlet UIButton *shiftButton;
@property (weak, nonatomic) IBOutlet UIButton *capLockButton;
@property (weak, nonatomic) IBOutlet UIButton *shiftRightButton;


enum TOUCH_TYPE
{
    TAP,
    SINGLE_DRAG,
    DOUBLE_DRAG,
    ZOOM
};

struct TOUCH_DATA
{
    enum TOUCH_TYPE type;  //0:tap, 1: single drag, 2:double drag, 3:zoom
    CGPoint location;
    CGFloat factor;  //only zoom has
};
@end
