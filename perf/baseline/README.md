# Baseline Profiling Notes

Date: 2026-04-17

## Devices Detected
- Android: `TECNO KL8h` (`137103151F031445`)
- iOS: `Har har mahadev` (`00008120-000E08912EB8C01E`)

## Commands Run
- `flutter --version`
- `flutter devices`
- `flutter run --profile -d 137103151F031445 --trace-startup --verbose-system-logs --start-paused --no-resident`
- `flutter run --profile -d 137103151F031445 --trace-startup --no-resident`

## Captured Artifacts
- `perf/baseline/android_profile_startup.log`
- `perf/baseline/android_startup_trace.log` (partial run)

## Notes
- Profile startup commands were initiated and logs captured.
- End-to-end flow traces (Mart, Search/Deals, Orders) require interactive in-app navigation while attached in profile mode, then timeline export from DevTools. This run prepared baseline artifacts and commands in-repo but did not include full interactive timeline exports.
