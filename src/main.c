// ... includes same as before

int main(int argc, char *argv[]) {
    // ... same init up to display_init

    // Open game controller
    SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
    SDL_GameController *ctrl = NULL;
    if (SDL_NumJoysticks() > 0) {
        ctrl = SDL_GameControllerOpen(0);
        fprintf(stderr, "Controller: %s\n", ctrl ? SDL_GameControllerName(ctrl) : "none");
    }

    int running = 1;
    SDL_Event ev;
    // ... other vars

    while (running) {
        // ... clock drawing, alarm check, etc.

        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;
            else if (ev.type == SDL_CONTROLLERBUTTONDOWN) {
                fprintf(stderr, "Button down: %d\n", ev.cbutton.button);
                // Map button numbers to actions
                switch (ev.cbutton.button) {
                    case SDL_CONTROLLER_BUTTON_A: // usually 0
                        // A button press
                        break;
                    case SDL_CONTROLLER_BUTTON_B: // usually 1
                        running = 0;
                        break;
                    case SDL_CONTROLLER_BUTTON_DPAD_UP:
                        break;
                    case SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                        break;
                    // add others
                }
            }
        }
        SDL_Delay(50);
    }

    // ... cleanup
}