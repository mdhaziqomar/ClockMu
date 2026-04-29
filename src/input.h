#ifndef INPUT_H
#define INPUT_H

#include <SDL2/SDL.h>

typedef enum {
    BUTTON_NONE,
    BUTTON_UP, BUTTON_DOWN, BUTTON_LEFT, BUTTON_RIGHT,
    BUTTON_A, BUTTON_B, BUTTON_X, BUTTON_Y,
    BUTTON_START, BUTTON_SELECT,
    BUTTON_L1, BUTTON_R1,
    BUTTON_QUIT
} Button;

void input_init(void);
void input_update(void);
int input_just_pressed(Button btn);
int input_any_pressed(void);
void input_close(void);

#endif