# Changelog

## [v0.1.0 - Milestone 1 MVP](https://github.com/NU-CS-Software-Studio-Spring-26/project-nu-sublets/releases/tag/v0.1.0)

Initial public-facing MVP release for NU Sublets.

### Added
- User authentication with Northwestern email.
- Login/logout flow with flash notifications.
- Protected listing creation flow requiring users to be logged in.
- Authorization checks to prevent users from accessing or modifying other users’ listings.
- Listing creation with photo upload and display.
- Richer listing details, including utilities, furnished status, roommates, amenities, availability dates, lease duration, and contact information.
- Contact information visibility restricted to logged-in users.
- Search and browse functionality for listings.
- Filters for location, price, beds, baths, housing type, and duration.
- Sorting by newest and price.
- Favorites/save listing functionality.
- Improved listing card UI.
- Mobile-responsive layout improvements.
- Empty states and no-results handling.
- Calendar start/end date selection fixes.
- Realistic seed data for demo listings and users.
- Basic automated tests for model validations, associations, protected routes, search filters, and listing ownership permissions.

### Changed
- Added consistent global layout/navigation.
- Added consistent flash styling.
- Refactored repeated view logic into partials where appropriate.
- Removed unused, debug, and non-functional code.
- Applied linters and cleaned code style.

### Security / Configuration
- Moved secrets and sensitive configuration to environment variables.
- Ensured password-protected pages are not accessible by direct URL.
- Prevented invalid login behavior from leaking whether an email exists.

### Notes
- This release represents the Milestone 1 MVP: a new user can complete the core NU Sublets workflow end-to-end, including signing up, browsing/searching listings, saving listings, and creating a listing.