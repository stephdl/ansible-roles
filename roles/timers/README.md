# timers

This roles manage systemd timers, to execute commands at regular interval.
Just define the timers you want at the host, or group level, like :

```
system_timers:
  - id: db-janitor     # Just an identifier for the task
    calendar: '*:0/30' # See man systemd.timer for examples
    max_duration: 1h   # Max duration of the task. Will be terminated if it takes longer
    command: |
      #!/bin/bash
      psql -U postgres -d reports -w << _EOF
        delete from audit where time < now()-'7 day'::interval;
      _EOF
  - id: logrotate
    calendar: daily
    command: logrotate -f /etc/logrotate.d/myservice.conf
```

Look at the defaults/main.yml file for more info
