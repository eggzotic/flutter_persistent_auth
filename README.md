# flutter_persistent_auth

The original "flutter create" app re-written entirely with Stateless Widgets, using Provider to hold the app-state data. And now, also including:
- persistent storage for the app state, via Google Cloud Firestore
- data-sharing, for the state data - run simultaneously in multiple simulators/emulators/devices to see real-time data-sharing
- single user (aka app-level) authentication to assist in DB-data-access management

## Getting Started

This project is the fourth in a series
- starting from the default Flutter starter app
- 1. converting to all-Stateless Widgets
- 2. adding persistent local-storage
- 3. then replacing it with persistent & shared data via Google Cloud Firestore
- 4. now adding single-user, app-level authentication
 
The repo for the previous edition is at https://github.com/eggzotic/flutter_persistent_cloud

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)
- [Provider Package](https://pub.dev/packages/provider)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Richard Shepherd  
December 2019