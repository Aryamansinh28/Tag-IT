# Tag-IT — Civic Waste Reporting and Cleanup Platform

Tag-IT is a mobile application that helps communities report waste-disposal issues, visualize reported locations, and coordinate cleanup activities. It combines location-based reporting, AI-assisted waste analysis, community participation, and cleanup campaigns.

## Features

- **User Authentication:** Sign in to access the application.
- **Waste Reporting:** Capture waste images and submit reports with location information.
- **AI-Assisted Analysis:** Analyze submitted waste images using the backend AI service.
- **Community Feed:** Browse submitted reports and view their cleanup status.
- **Waste Map:** View reported waste locations on an interactive map.
- **Cleanup Verification:** Submit cleanup evidence, including before-and-after photos and location information.
- **Cleaned Projects:** View completed cleanup records.
- **Campaigns:** Browse and create community cleanup campaigns.

## Technology Stack

| Component | Technology |
|---|---|
| Mobile frontend | Flutter, Dart |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Backend API | Python, FastAPI |
| AI image analysis | Google Gemini |
| Image hosting | ImageKit |
| Maps and location | Google Maps Platform |

## Project Structure

```text
Tag-IT/
├── app/                 # Flutter mobile application
│   └── lib/
│       ├── screens/     # Application screens
│       └── services/    # App services and integrations
├── backend/             # FastAPI backend
├── docs/                # Project documentation
└── README.md
```

## System Overview

The Flutter application provides the user interface and communicates with Firebase and the backend services.

- Firebase Authentication manages user sign-in.
- Cloud Firestore stores application data, including waste reports and cleanup records.
- The FastAPI backend exposes the waste-analysis endpoint.
- The backend uses Google Gemini to analyze submitted waste images.
- ImageKit is used for image hosting.
- Google Maps Platform provides map and location functionality.

## Setup and Installation

### Prerequisites

Install the following before running the project:

- Flutter SDK
- Dart SDK
- Android Studio or another supported Flutter development environment
- Python 3
- A Firebase project configured for the application
- Required API credentials for the integrated services

### Run the Flutter Application

1. Clone the repository:

   ```bash
   git clone <REPOSITORY_URL>
   cd Tag-IT
   ```

2. Navigate to the Flutter app:

   ```bash
   cd app
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Configure Firebase and the required API credentials using the project's setup files and your development environment.

5. Run the application:

   ```bash
   flutter run
   ```

### Run the Backend Locally

1. Open a terminal in the `backend/` directory.
2. Create and activate a Python virtual environment:

   ```bash
   python -m venv .venv
   ```

   Windows:

   ```bash
   .venv\Scripts\activate
   ```

3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

4. Configure the required environment variables. Do not commit private credentials or `.env` files.

5. Start the FastAPI server using the backend's configured entry point.

The deployed backend is hosted at:

`https://tag-it-backend.onrender.com`


The repository contains the Flutter application, backend implementation, and project documentation.

## Security

- Do not commit private credentials, access tokens, or `.env` files.
- Restrict Google API keys to the required APIs and application identifiers.
- Configure Firebase Authentication and Firestore security rules appropriately.

## Project Documentation

Additional documentation is available in the `docs/` directory, including architecture, database schema, navigation flow, technology stack, and user flow.


