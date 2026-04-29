#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>
#include <time.h>

typedef struct {
    uint8_t alarm_enabled;
    uint8_t alarm_hour;
    uint8_t alarm_min;
    uint8_t snooze_minutes;
    uint8_t alarm_triggered;
    time_t next_alarm_time;
} Config;

void config_load(Config *cfg);
void config_save(const Config *cfg);
void config_set_next_alarm(Config *cfg, time_t now);

#endif