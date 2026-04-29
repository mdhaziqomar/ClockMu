#include "alarm.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

Mix_Chunk *alarm_sound = NULL;
static int sound_playing = 0;

void alarm_start_alert(void) {
    // Brightness full
    system("echo 255 > /sys/class/backlight/muos-bl/brightness 2>/dev/null || echo 255 > /sys/class/backlight/backlight/brightness");
    // Vibrator (if present)
    system("echo 1 > /sys/class/leds/vibrator/enable 2>/dev/null");
    if (alarm_sound && !sound_playing) {
        Mix_PlayChannel(-1, alarm_sound, -1);
        sound_playing = 1;
    }
}

void alarm_stop_alert(void) {
    if (sound_playing) {
        Mix_HaltChannel(-1);
        sound_playing = 0;
    }
    system("echo 0 > /sys/class/leds/vibrator/enable 2>/dev/null");
}

void alarm_snooze(Config *cfg, time_t now) {
    alarm_stop_alert();
    cfg->alarm_triggered = 0;
    time_t snooze_until = now + cfg->snooze_minutes * 60;
    struct tm *tm = localtime(&snooze_until);
    cfg->alarm_hour = tm->tm_hour;
    cfg->alarm_min = tm->tm_min;
    config_set_next_alarm(cfg, snooze_until);
    config_save(cfg);
}

void alarm_add_minute(Config *cfg) {
    if (cfg->snooze_minutes < 60) cfg->snooze_minutes++;
    config_save(cfg);
}

void alarm_check_and_trigger(Config *cfg, time_t now) {
    if (!cfg->alarm_enabled) return;
    if (cfg->alarm_triggered) return;
    if (cfg->next_alarm_time > 0 && now >= cfg->next_alarm_time) {
        cfg->alarm_triggered = 1;
        config_save(cfg);
        alarm_start_alert();
    }
}