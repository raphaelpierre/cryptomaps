# CryptoMaps v1.2.0 - Performance & Caching Update

## New Features & Improvements
- **Enhanced Caching System**: Multi-level memory and disk caching reduces API calls by up to 80%
- **Detail View for Global Market Coins**: Interactive visualization of cryptocurrency market dominance
- **Smarter Network Layer**: Automatic retry with exponential backoff for improved reliability
- **Cross-View State Sharing**: Optimized ViewModels to share data between views
- **Performance Optimizations**: Component extraction, lazy loading, and reduced recomputation

## Technical Improvements
- Extended cache duration from 30 seconds to 10 minutes for better offline experience
- Implemented memory-first approach with UserDefaults fallback for faster data access
- Added time-based caching for price history data to reduce redundant API calls
- Fixed Codable conformance issues in data models
- Optimized rendering performance with extracted component views
- Added missing compiler compatibility for tvOS 17

## Bug Fixes
- Resolved black screen issue in GlobalDetailView when navigating back
- Fixed layout issues in circular progress indicators
- Eliminated memory leaks in image loading and caching
- Improved error handling with graceful degradation when offline

## Developer Notes
This update focuses on performance, reliability, and network efficiency. Users should experience faster loading times, reduced API rate limit errors, and better offline functionality.
