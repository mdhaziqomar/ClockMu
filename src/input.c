#include "input.h"
#include <stdio.h>
#include <string.h>

static SDL_GameController *ctrl = NULL;
static int initialized = 0;

void input_init(void) {
    SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
    // Try to open the first available joystick as a game controller
    if (SDL_NumJoysticks() > 0) {
        ctrl = SDL_GameControllerOpen(0);
        if (ctrl) {
            fprintf(stderr, "Opened controller: %s\n", SDL_GameControllerName(ctrl));
        } else {
            fprintf(stderr, "Failed to open controller\n");
        }
    } else {
        fprintf(stderr, "No joysticks found\n");
    }
    initialized = 1;
}

void input_update(void) {
    // No need – we poll events in main loop
}

int input_just_pressed(Button btn) {
    // This function is called after we process SDL events.
    // We'll set flags in the event handler instead.
    // Simpler: we'll store button states in a static array.
    return 0; // Placeholder – we'll rewrite approach
}

// We'll handle button states via SDL events directly in main.c
// For now, let's just log events in main.c. I'll show you how.