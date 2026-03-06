# Grade Calculator

A professional Flutter application for calculating and managing student grades across multiple subjects. Supports manual data entry and Excel file import, with PDF and Excel report generation.

## Features

- **Multi-Subject Grading** — Enter any number of subjects per student with individual CA and Test scores
- **Manual Entry** — Step-by-step flow: set class size and subject count, name subjects, then enter scores
- **Excel Import** — Upload `.xlsx` files to bulk-import student data
- **Auto Grade Calculation** — Automatically computes totals, averages, and letter grades (A through F)
- **Expandable Results** — View per-subject score breakdowns for each student
- **Class Statistics** — Highest, lowest, average scores, pass/fail counts, and grade distribution chart
- **Export to Excel** — Download graded results as a `.xlsx` file with the Grade column added
- **Export to PDF** — Generate a formatted PDF report with statistics and grade distribution
- **Share** — Share generated Excel/PDF files directly from the app

## Architecture

The project follows a clean separation of concerns using OOP principles:

```
lib/
├── interfaces/       # Abstract classes (GradeStrategy)
├── models/           # Data models (Student, SubjectScore, GradeResult, Subject)
├── services/         # Business logic (GradeCalculator, StudentManager, ExcelHandler, PdfHandler)
├── screens/          # UI screens (Home, ManualEntry, ExcelUpload, Results)
├── widgets/          # Reusable UI components (GradientButton, PremiumCard, PremiumTextField)
├── theme/            # App-wide theme and styling
└── main.dart         # App entry point
```

**Key OOP patterns:**
- `GradeStrategy` interface with `GradeCalculator` implementation
- `StudentManager` with dependency injection and higher-order functions
- Lambda expressions and functional-style data transformations throughout

## Dependencies

| Package | Purpose |
|---------|---------|
| `excel` | Read/write `.xlsx` files |
| `pdf` | Generate PDF reports |
| `file_picker` | Select Excel files for import |
| `path_provider` | Access device storage for exports |
| `share_plus` | Share exported files |
| `permission_handler` | Handle file system permissions |

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Junkey06/grade_calc.git
   cd grade_calc
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## Platforms

Android, iOS, Web, Windows, macOS, Linux
