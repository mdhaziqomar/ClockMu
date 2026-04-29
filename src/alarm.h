#ifndef ALARM_H
#define ALARM_H

#include <SDL2/SDL_mixer.h>
#include "config.h"

extern Mix_Chunk *alarm_sound;

void alarm_check_and_trigger(Config *cfg, time_t now);
void alarm_start_alert(void);
void alarm_stop_alert(void);
void alarm_snooze(Config *cfg, time_t now);
void alarm_add_minute(Config *cfg);

#endif