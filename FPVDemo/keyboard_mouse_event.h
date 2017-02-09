//
//  keyboard_mouse_event.h
//  FPVDemo
//
//  Created by xuhao on 2017/2/9.
//  Copyright © 2017年 DJI. All rights reserved.
//

#ifndef keyboard_mouse_event_h
#define keyboard_mouse_event_h
#include "stdio.h"
#define SCREEN_WITDH 1280
#define SCREEN_HEIGHT 720
#define MAX_COMBO_KEY 5
enum EVENT_TYPE{
    KEYBOARD_EVENT = 0,
    MOUSE_MOVE_EVENT = 1,
    MOUSE_PRESS_EVENT = 2
};

struct __attribute__((__packed__)) key_mouse_event{
    uint8_t event_type;
    int16_t data[5];
};

int key_mouse_event_to_msg(uint8_t *msg,struct key_mouse_event * event);
void mouse_press_to_event(struct key_mouse_event *event,int mousex,int mousey,int button);
void keyboard_to_event(struct key_mouse_event * event,int * keys);
void mouse_move_to_event(struct key_mouse_event * event,int mousex,int mousey);
#endif /* keyboard_mouse_event_h */
