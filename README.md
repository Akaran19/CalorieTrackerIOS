# STILL WORK IN PROGRESS

# CalorieCam

A comprehensive iOS app for photo-based calorie tracking and nutrition management.

## Features

### Core Functionality
- **Photo-based Meal Logging**: Take photos of meals for instant AI-powered calorie estimation
- **AI Integration**: Seamless integration with Zapier webhook for calorie and macro estimation
- **Meal History**: Searchable meal log with date filtering and detailed meal views
- **Macro Tracking**: Track protein, carbs, and fat with visual progress indicators
- **Streak System**: Gamified logging and goal streaks to build healthy habits
- **Daily Progress**: Visual progress rings and macro pills for daily overview

### User Experience
- **Modern UI**: Apple Health-inspired design with clean, intuitive interface
- **Dark Mode**: Automatic dark mode support following system preferences
- **Accessibility**: Full VoiceOver support and accessibility labels
- **Onboarding**: Comprehensive onboarding flow for new users
- **Settings**: Complete settings management with profile editing

### Data Management
- **Core Data**: Robust local data storage with SQLite backend
- **Image Storage**: Efficient image storage with thumbnails for performance
- **Data Export**: CSV export functionality for data portability
- **Privacy**: All data stored locally with optional cloud sync

## Technical Architecture

### Core Components
- **MVVM Architecture**: Clean separation of concerns with SwiftUI
- **Core Data Stack**: Persistent storage with background context support
- **Service Layer**: Modular services for AI, streaks, and data management
- **Image Processing**: Efficient image handling with thumbnail generation

### Key Services
- `AICalorieService`: Handles AI calorie estimation requests
- `StreakEngine`: Manages streak calculations and updates
- `PersistenceController`: Core Data stack management
- `ImageService`: Image storage and thumbnail generation

### Data Models
- `UserProfile`: User information and goals
- `Meal`: Meal data with nutrition information
- `DailySummary`: Daily nutrition summaries
- `Streak`: Streak tracking data
- `AnalyticsEvent`: Analytics and tracking events

## Setup and Installation

### Prerequisites
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `CalorieTracker.xcodeproj` in Xcode
3. Build and run the project

### Configuration
- The app uses the existing Zapier webhook at `https://hooks.zapier.com/hooks/catch/23448574/u3mpie6/`
- No additional configuration required for basic functionality

## Usage

### Getting Started
1. Launch the app
2. Complete the onboarding process to set up your profile
3. Start logging meals by taking photos
4. View your progress on the home dashboard
5. Track your streaks and goals

### Key Workflows
- **Logging a Meal**: Take a photo → Add context → Submit → AI estimation → Meal saved
- **Viewing History**: Navigate to Log tab → Search/filter meals → View details
- **Managing Streaks**: Check Streaks tab → View progress → Stay motivated
- **Settings**: Access via Settings tab → Edit profile → Manage preferences

## Development

### Project Structure
```
CalorieTracker/
├── Views/
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── MealHistoryView.swift
│   ├── PhotoSubmissionView.swift
│   ├── StreaksView.swift
│   ├── SettingsView.swift
│   └── OnboardingView.swift
├── Models/
│   └── CalorieCam.xcdatamodeld/
├── Services/
│   ├── AICalorieService.swift
│   ├── StreakEngine.swift
│   └── PersistenceController.swift
└── Supporting Files/
    ├── Assets.xcassets/
    └── Info.plist
```

### Adding New Features
1. Create new SwiftUI views in the Views directory
2. Add Core Data models if needed
3. Implement services for business logic
4. Update navigation and integration

## Privacy and Data

### Data Storage
- All data stored locally on device
- Images stored in app sandbox
- No cloud sync in current version
- Optional data export functionality

### Privacy Features
- Camera and photo library permissions only when needed
- No data sharing with third parties (except AI service)
- User control over data deletion
- Transparent privacy policy

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue on GitHub or contact the development team.
