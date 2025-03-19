# Changelog

All notable changes to CryptoMaps will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2024-06-01

### Added
- Detailed view for Global Market coin dominance
- Enhanced caching system with memory-first approach
- Automatic retry mechanism for network failures
- Improved image caching across the app
- Time-based caching for price history data
- Shared view model architecture for better state management

### Changed
- Extended cache expiration from 30 seconds to 10 minutes
- Improved error handling with graceful fallback to cached data
- Optimized TokenDetailView with component extraction
- Enhanced GlobalView with interactive dominance cards
- Optimized SectorDetailView with fixed-height containers
- Reduced redundant API calls with smarter fetch logic

### Fixed
- Black screen issue in GlobalDetailView
- Compiler warnings related to onChange in tvOS 17
- Layout issues in circular progress indicators
- Memory leaks in image loading and caching
- Performance bottlenecks in data formatting
- Codable conformance issues in data models

## [1.1.0] - 2024-05-15

### Added
- Support for additional cryptocurrency tokens
- Performance metrics tracking
- Enhanced error handling for API requests
- Improved caching mechanism for faster data loading

### Changed
- Optimized UI rendering for better performance
- Improved data refresh mechanism to reduce API calls
- Enhanced watchlist functionality with better sorting options
- Updated CoinGecko API integration for more reliable data

### Fixed
- UI glitches in dark mode
- Memory leak in market data processing
- Incorrect price formatting for certain currencies
- Watchlist synchronization issues

## [1.0.0] - 2024-03-20

### Added
- Real-time cryptocurrency price tracking using CoinGecko API
- Global market overview with market capitalization distribution
- Detailed token information view with comprehensive market data
- Interactive token cards with high-quality logos and price indicators
- Personalized watchlist functionality
  - Add/remove tokens via long-press gesture
  - Dedicated watchlist tab for quick access
  - Visual indicators for watchlisted tokens
- Tab-based navigation system
- Smart number formatting for large financial values
- Visual price change indicators (green/red)
- Settings view for user preferences
- Sector-based cryptocurrency grouping and analysis
- Currency settings for price display preferences

### Changed
- Migrated from Binance API to CoinGecko API for improved data reliability
- Enhanced UI/UX with modern design patterns
- Improved asset management system

### Removed
- Legacy Binance service integration
- Deprecated CryptoLogoImage component
- Old app icon assets

[1.2.0]: https://github.com/raphaelpierre/cryptomaps/releases/tag/v1.2.0
[1.1.0]: https://github.com/raphaelpierre/cryptomaps/releases/tag/v1.1.0
[1.0.0]: https://github.com/raphaelpierre/cryptomaps/releases/tag/v1.0.0 