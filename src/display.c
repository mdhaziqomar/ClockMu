#include "display.h"
#include <stdio.h>

static SDL_Renderer *renderer = NULL;
static int screen_w, screen_h;

void draw_large_digit(SDL_Renderer *ren, int digit, int x, int y, int w, int h) {
    // 3x5 pattern for digits 0-9 (1 = on)
    const char patterns[10][15] = {
        {1,1,1, 1,0,1, 1,0,1, 1,0,1, 1,1,1}, // 0
        {0,0,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1}, // 1
        {1,1,1, 0,0,1, 1,1,1, 1,0,0, 1,1,1}, // 2
        {1,1,1, 0,0,1, 1,1,1, 0,0,1, 1,1,1}, // 3
        {1,0,1, 1,0,1, 1,1,1, 0,0,1, 0,0,1}, // 4
        {1,1,1, 1,0,0, 1,1,1, 0,0,1, 1,1,1}, // 5
        {1,1,1, 1,0,0, 1,1,1, 1,0,1, 1,1,1}, // 6
        {1,1,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1}, // 7
        {1,1,1, 1,0,1, 1,1,1, 1,0,1, 1,1,1}, // 8
        {1,1,1, 1,0,1, 1,1,1, 0,0,1, 1,1,1}  // 9
    };
    int cell_w = w / 3;
    int cell_h = h / 5;
    for (int row = 0; row < 5; row++) {
        for (int col = 0; col < 3; col++) {
            if (patterns[digit][row*3 + col]) {
                SDL_Rect r = { x + col*cell_w, y + row*cell_h, cell_w, cell_h };
                SDL_RenderFillRect(ren, &r);
            }
        }
    }
}

void display_init(SDL_Renderer *ren, int w, int h) {
    renderer = ren;
    screen_w = w;
    screen_h = h;
}

void display_draw_clock(SDL_Renderer *ren, const struct tm *tm, const Config *cfg) {
    SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
    SDL_RenderClear(ren);
    SDL_SetRenderDrawColor(ren, 255, 255, 255, 255);

    int digit_w = screen_w / 10;
    int digit_h = digit_w * 1.4;
    int start_x = (screen_w - (digit_w * 5 + digit_w/2)) / 2;
    int start_y = (screen_h - digit_h) / 2 - 30;

    char time_str[5];
    snprintf(time_str, sizeof(time_str), "%02d%02d", tm->tm_hour, tm->tm_min);
    for (int i = 0; i < 4; i++) {
        int digit = time_str[i] - '0';
        int x = start_x + i * (digit_w + digit_w/4);
        if (i >= 2) x += digit_w/2; // skip colon space
        draw_large_digit(ren, digit, x, start_y, digit_w, digit_h);
    }
    // Draw colon
    int colon_x = start_x + 2 * (digit_w + digit_w/4) + digit_w/4;
    int colon_y = start_y + digit_h/3;
    SDL_Rect colon_top = { colon_x, colon_y, digit_w/6, digit_w/6 };
    SDL_Rect colon_bot = { colon_x, colon_y + digit_h/3, digit_w/6, digit_w/6 };
    SDL_RenderFillRect(ren, &colon_top);
    SDL_RenderFillRect(ren, &colon_bot);

    // Alarm indicator
    if (cfg->alarm_enabled) {
        SDL_SetRenderDrawColor(ren, 0, 255, 0, 255);
        SDL_Rect indicator = { screen_w - 30, 10, 20, 20 };
        SDL_RenderFillRect(ren, &indicator);
    }
    // Snooze indicator (when alarm triggered)
    if (cfg->alarm_triggered) {
        SDL_SetRenderDrawColor(ren, 255, 0, 0, 255);
        SDL_Rect indicator = { screen_w - 30, 40, 20, 20 };
        SDL_RenderFillRect(ren, &indicator);
    }
    SDL_RenderPresent(ren);
}

void display_cleanup(void) {}