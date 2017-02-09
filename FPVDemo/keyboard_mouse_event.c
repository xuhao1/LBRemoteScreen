//
//  keyboard_mouse_event.c
//  FPVDemo
//
//  Created by xuhao on 2017/2/9.
//  Copyright © 2017年 DJI. All rights reserved.
//

#include <stdio.h>
#include "keyboard_mouse_event.h"
#include "string.h"

int key_mouse_event_to_msg(uint8_t *msg,struct key_mouse_event * event)
{
    int len =sizeof(struct key_mouse_event);
    memset(msg,0,len);
    memcpy(msg, event, len);
    return len;
}

void keyboard_to_event(struct key_mouse_event * event,int * keys)
{
    memset(event, 0, sizeof(struct key_mouse_event));
    event->event_type = KEYBOARD_EVENT;
    for(int i = 0 ;i < MAX_COMBO_KEY;i++)
        event->data[i] = keys[i];
}

void mouse_move_to_event(struct key_mouse_event * event,int movex,int movey)
{
    memset(event, 0, sizeof(struct key_mouse_event));
    event->event_type = MOUSE_MOVE_EVENT;
    event->data[0] = movex;
    event->data[1] = movey;
}

void mouse_press_to_event(struct key_mouse_event *event,int mousex,int mousey,int button)
{
    memset(event, 0, sizeof(struct key_mouse_event));
    event->event_type = MOUSE_PRESS_EVENT;
    event->data[0] = mousex;
    event->data[1] = mousey;
    event->data[2] = button;
}
