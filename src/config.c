#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CONFIG_FILE "config.txt"

static const Config default_config = {
    .alarm_enabled = 0,
    .alarm_hour = 7,
    .alarm_min = 0,
    .snooze_minutes = 5,
    .alarm_triggered = 0,
    .next_alarm_time = 0
};

void config_load(Config *cfg) {
    *cfg = default_config;
    FILE *f = fopen(CONFIG_FILE, "r");
    if (!f) return;
    char line[128];
    while (fgets(line, sizeof(line), f)) {
        int val;
        if (sscanf(line, "alarm_enabled=%d", &val) == 1) cfg->alarm_enabled = val;
        else if (sscanf(line, "alarm_hour=%d", &val) == 1 && val >= 0 && val < 24) cfg->alarm_hour = val;
        else if (sscanf(line, "alarm_min=%d", &val) == 1 && val >= 0 && val < 60) cfg->alarm_min = val;
        else if (sscanf(line, "snooze_minutes=%d", &val) == 1) cfg->snooze_minutes = val;
        else if (sscanf(line, "alarm_triggered=%d", &val) == 1) cfg->alarm_triggered = val;
        else if (sscanf(line, "next_alarm_time=%lld", (long long*)&cfg->next_alarm_time) == 1);
    }
    fclose(f);
}

void config_save(const Config *cfg) {
    FILE *f = fopen(CONFIG_FILE, "w");
    if (!f) return;
    fprintf(f, "alarm_enabled=%d\n", cfg->alarm_enabled);
    fprintf(f, "alarm_hour=%d\n", cfg->alarm_hour);
    fprintf(f, "alarm_min=%d\n", cfg->alarm_min);
    fprintf(f, "snooze_minutes=%d\n", cfg->snooze_minutes);
    fprintf(f, "alarm_triggered=%d\n", cfg->alarm_triggered);
    fprintf(f, "next_alarm_time=%lld\n", (long long)cfg->next_alarm_time);
    fclose(f);
}

void config_set_next_alarm(Config *cfg, time_t now) {
    struct tm *tm = localtime(&now);
    tm->tm_hour = cfg->alarm_hour;
    tm->tm_min = cfg->alarm_min;
    tm->tm_sec = 0;
    time_t next = mktime(tm);
    if (next <= now) next += 24*3600;
    cfg->next_alarm_time = next;
    config_save(cfg);
}