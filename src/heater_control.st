(* Water heater controller - program body for "main" (Structured Text) *)
(* Scaling: TEMP_SIM 0..1023 -> 0..150 degC, LEVEL_SIM 0..1023 -> 0..100 % *)
TEMP_C    := INT_TO_REAL(TEMP_SIM) * 150.0 / 1023.0;
LEVEL_PCT := INT_TO_REAL(LEVEL_SIM) * 100.0 / 1023.0;

(* Thermostat conditions with hysteresis *)
T_LOW  := TEMP_C < SP - HYST;
T_HIGH := TEMP_C > SP + HYST;
T_OVER := TEMP_C > TEMP_LIMIT;

(* Dry-fire protection: cut off below 25 %, resume above 30 % *)
IF LEVEL_PCT < LVL_CUTOFF THEN
  LVL_LOW_RAW := TRUE;
ELSIF LEVEL_PCT > LVL_RESUME THEN
  LVL_LOW_RAW := FALSE;
END_IF;

(* 2 s on-delay so a splash or noise does not trip the lockout *)
LVL_TMR(IN := LVL_LOW_RAW, PT := T#2s);
LVL_LOW     := LVL_TMR.Q;
LEVEL_ALARM := LVL_LOW;

(* Latching over-temperature alarm, start/stop latch, heater output *)
ALARM  := T_OVER OR (ALARM AND NOT (RESET_PB OR HMI_RESET));
RUN    := (START_PB OR HMI_START OR RUN) AND NOT (STOP_PB OR HMI_STOP) AND NOT ALARM;
HEATER := RUN AND NOT ALARM AND NOT LVL_LOW
          AND (T_LOW OR (HEATER AND NOT T_HIGH));
HMI_RUN := RUN;
