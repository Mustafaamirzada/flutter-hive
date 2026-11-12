# FluHiv — Aurora Student Hub

A modern Flutter application that reads academic data from a REST API
(`http://localhost:3000`), caches it **offline-first** with
[Hive](https://pub.dev/packages/hive), and presents it in a custom
**"Midnight Aurora"** design system — animated aurora blobs, frosted-glass
panels, gradient gauges and a GitHub-style attendance calendar.

---

## Use Case

FluHiv targets students of an institute whose backend exposes three data
routes. The app is designed so that **the API is the only source of truth for
data** — the UI never reads the network directly:

```
API (localhost:3000)  ──fetch──▶  DataRepository  ──persist──▶  Hive boxes  ──listenable──▶  Screens
        │                                │                          │
        └── offline? keep serving ───────┘          UI rebuilds     └── homework toggle is
                                                     on every         written back locally
                                                     change
```

| Route | Data | Screen |
|---|---|---|
| `/scores` | Subject grades, GPA, averages, semester scores, attendance records (Solar-Hijri dates + `attendees` JSON), homework | **Scores** |
| `/new_courses` | Upcoming courses with title, description, category and start date | **Courses** |
| `/pdfs` | Shared PDF documents with course, teacher, category and time | **Documents** |

Key behaviours:

- **API → Hive → UI**: on launch (and on every refresh) the three routes are
  fetched in parallel, parsed into Hive-typed models and written to local
  boxes. Screens read through Hive `ValueListenable`s, so they rebuild
  automatically after a sync.
- **Offline resilience**: if the API is unreachable the app keeps serving the
  last cached Hive data; a SnackBar reports the sync state and offers *Retry*.
- **Attendance calendar**: attendance is rendered per Solar-Hijri month
  (`Sunbula 1405`, `Mizan 1405`, …) as a real calendar — Saturday-first columns,
  one row per week — with cells colored by status: green ✓ present, red absent,
  amber late, outlined gray = not recorded.
- **Homework tracking**: a gradient progress ring per subject; tapping a task
  toggles its completion and the change is **persisted into Hive** with derived
  counts/rates recomputed.
- **Light & Dark themes**: two variants of the same aurora identity
  (*Midnight Aurora* / *Soft Aurora*), switchable from the header and persisted
  in the Hive `fluhiv_settings` box.

---

## Screenshots

| Home (Scores) | Courses | Documents |
|---|---|---|
| ![Home screen](assets/screenshot/home%20screen.jpg) | ![Courses screen](assets/screenshot/courses%20screen.jpg) | ![PDFs screen](assets/screenshot/pdfs%20screen.jpg) |

---

## Project Structure

```
lib/
├── main.dart                       # App bootstrap, theme mode wiring
│
├── models/                         # Hive-typed data models
│   ├── models.dart                 #   barrel + JSON helper (asMap, asDouble…)
│   ├── score.dart                  #   Score + ScoreAdapter      (typeId 1)
│   ├── new_course.dart             #   NewCourse + adapter       (typeId 2)
│   └── pdf.dart                    #   CoursePdf + adapter       (typeId 3)
│
├── services/
│   ├── api_service.dart            # HTTP client for /scores /pdfs /new_courses
│   ├── hive_store.dart             # Box bootstrap, save/read, theme setting,
│   │                               #   homework toggle persistence
│   └── attendance_parser.dart      # Decodes `attendees` JSON strings into
│                                   #   per-day statuses, groups by month
│
├── repository/
│   └── data_repository.dart        # Sync orchestration: API → Hive, sync
│                                   #   result reporting
│
├── utils/
│   └── jalali_utils.dart           # Solar-Hijri (Jalali) dates: parsing,
│                                   #   Gregorian conversion, weekday math
│
└── ui/
    ├── theme.dart                  # Aurora design system: Tone (light/dark
    │                               #   chrome colors), themes, shared widgets
    ├── screens/
    │   ├── home_shell.dart         # Aurora background, header, glass nav bar
    │   ├── scores_screen.dart      # Score cards, gauges, heatmap, homework
    │   ├── courses_screen.dart     # Course cards with gradient banners
    │   └── pdfs_screen.dart        # PDF tiles
    └── widgets/
        ├── fx.dart                 # AuroraBackground, GlassPanel, GradientText,
        │                           #   GradientGauge, Entrance animations
        └── attendance_heatmap.dart # GitHub-style monthly calendar heatmap

assets/screenshot/                 # App screenshots used in this README
test/model_test.dart               # Unit tests: Jalali math, attendance
                                   #   parsing, model mapping
```

---

## Getting Started

### Prerequisites
- Flutter (developed & verified with 3.38 stable, Linux desktop target)
- The backend API running on `http://localhost:3000`

### Run

```bash
flutter pub get
flutter run -d linux          # desktop mode (verified)
# or: flutter run -d <device>
```

### Tests & analysis

```bash
flutter analyze               # static analysis (0 issues)
flutter test                  # 9 unit tests (Jalali, attendance, models)
```

---

## Technical Notes

- **Hive adapters are hand-written** (`ScoreAdapter`, `NewCourseAdapter`,
  `CoursePdfAdapter`) — no `build_runner` required. Nested attendance /
  semester / homework records are stored as dynamic maps, which Hive
  serializes natively.
- **Jalali dates**: the API returns Solar-Hijri dates such as `1405-06-09`.
  `lib/utils/jalali_utils.dart` ports the
  [jalaali-js](https://github.com/jalaali/jalaali-js) algorithm for exact
  Gregorian conversion and weekday alignment of the calendar grid.
- **Theme persistence**: the selected brightness is stored in Hive
  (`fluhiv_settings` → `light_mode`) and restored at startup.
- **Score cards are expandable** and glow in the color of the subject grade;
  grades map to colors A = emerald, B = cyan, C = amber, D = orange, F = rose.
