#ifndef DISPLAY_H
#define DISPLAY_H

#include <SDL2/SDL.h>
#include <time.h>
#include "config.h"

void display_init(SDL_Renderer *ren, int screen_w, int screen_h);
void display_draw_clock(SDL_Renderer *ren, const struct tm *tm, const Config *cfg);
void display_cleanup(void);

#endif