# AGENTS.md

## Project Overview

NU Sublets is a Ruby on Rails application for Northwestern students to post, browse, search, filter, and save sublet listings. The app is intentionally student-gated: account creation and login should only accept approved Northwestern email domains.

Core user-facing capabilities include:

- Local email/password signup and login with `has_secure_password`.
- Google OAuth login through OmniAuth when `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are configured.
- Firebase ID token login support through `SessionsController#create` when an `id_token` is posted.
- Listing creation for authenticated users.
- Listing browsing, detail pages, search, filters, sorting, pagination, and empty states.
- Active Storage uploads for listing photos and user profile photos.
- Profile pages, saved listings UI, and owner-only listing management.
- PWA manifest and service worker assets.

Production deployment is configured for Heroku/PostgreSQL. Development and test use SQLite.

## Stack

- Ruby `4.0.2` from `.ruby-version`
- Rails `~> 8.1.3`
- SQLite for development/test
- PostgreSQL in production
- Propshaft, Importmap, Turbo, Stimulus
- Active Storage for uploads
- Pagy for pagination
- OmniAuth Google OAuth plus local password auth
- Minitest, Capybara, Selenium for tests
- RuboCop, ERB Lint, Brakeman, bundler-audit, and importmap audit for quality/security checks

## Repository Map

- `app/models/user.rb`: user validation, Northwestern email domain checks, password auth, OAuth user creation, profile photo validation.
- `app/models/sublet_listing.rb`: listing validations, search/filter logic, allowed amenity/preference labels, upload limits.
- `app/controllers/pages_controller.rb`: main page flows, search results, profile updates, listing creation from the post-sublet form.
- `app/controllers/sublet_listings_controller.rb`: authenticated owner-only listing update/delete.
- `app/controllers/sessions_controller.rb`: local password login, OmniAuth callback handling, Firebase ID token login, logout.
- `app/controllers/registrations_controller.rb`: local signup.
- `app/views/pages`: most page templates. Several controllers use `layout false`, so page templates often carry full-page structure.
- `app/views/shared`: shared logo, footer, PWA metadata, and service worker partials.
- `app/assets/stylesheets/application.css`: primary CSS.
- `config/routes.rb`: custom routes rather than a fully RESTful listing resource.
- `db/migrate` and `db/schema.rb`: database structure. Use migrations for schema changes.
- `db/seeds.rb`: demo data.
- `test`: model, controller, integration, helper, auth, PWA, and flow tests.
- `.github/workflows/ci.yml`: CI jobs for security scans, linting, tests, and system tests.

## Domain Rules To Preserve

- Allowed student email domains are defined in `User::NORTHWESTERN_EMAIL_DOMAINS`:
  - `u.northwestern.edu`
  - `northwestern.edu`
  - `ads.northwestern.edu`
- Listing prices must be greater than `0` and at most `20,000`.
- Bedrooms and bathrooms must be integers from `0` to `20`.
- `available_until` must be after `available_from`.
- `available_from` cannot be in the past.
- Listing amenities and preferences must come from the allowlists in `SubletListing`.
- A listing can have at most 5 photos.
- Listing photos must be PNG, JPG/JPEG, or WebP and each must be 5 MB or smaller.
- User profile photos may be PNG, JPG/JPEG, WebP, or GIF.
- Listing contact or management features should stay protected behind authentication where currently required.
- Only listing owners should be able to update or delete their own listings.

## Common Commands

Install dependencies:

```sh
bundle install
```

Prepare the database:

```sh
bin/rails db:prepare
```

Seed demo data:

```sh
bin/rails db:seed
```

Run the development server:

```sh
bin/rails server
```

Run tests:

```sh
bin/rails test
```

Run the full local CI sequence:

```sh
bin/ci
```

Useful targeted checks:

```sh
bin/rubocop
bin/erblint
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/importmap audit
RAILS_ENV=test bin/rails db:seed:replant
```

## Environment Notes

- Do not commit `.env`, credentials, OAuth secrets, Firebase secrets, or production credentials.
- Google OAuth uses `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.
- `.env.example` currently lists Firebase browser config keys. Keep any real Firebase values out of git.
- For local Google OAuth development, the callback path is `/auth/google_oauth2/callback`.
- Production should not expose stack traces or debug details.

## Testing Guidance

- Add or update tests when touching model validations, search/filter behavior, authentication, authorization, uploads, routes, or profile/listing flows.
- Prefer focused tests near the changed behavior:
  - model tests for validation/search logic,
  - controller tests for status/redirect/permission behavior,
  - integration tests for user flows.
- If changing PWA assets, service worker behavior, or manifest behavior, run the PWA-related tests.
- If changing views heavily, run relevant integration/system tests and check mobile/desktop layout manually when possible.

## Implementation Notes

- Follow existing Rails conventions in this repo and keep changes tightly scoped.
- Use migrations for database changes; do not hand-edit `db/schema.rb` except as generated by Rails.
- Keep auth failures generic where they could reveal account existence.
- Normalize/validate user input through models or strong params rather than view-only checks.
- The app uses custom routes like `post-sublet`, `search-results`, and `listings/:id`; check `config/routes.rb` before adding new paths.
- Some code uses SQLite-friendly serialized JSON text columns for `amenities` and `preferences`; be careful with database-specific SQL if it needs to work in both development/test and production.
- Active Storage records are part of the schema. Be cautious when changing upload validations because tests and seed data may attach files.
- Several views are full-page ERB templates because controllers use `layout false`; verify shared partials and duplicated page structure before broad layout changes.

## Before Finishing Work

- Run the narrowest relevant test command first, then broader checks when the change has wider impact.
- For code changes, at minimum consider `bin/rails test`; for user-facing or security-sensitive changes, consider `bin/ci`.
- Check `git status --short` and avoid reverting unrelated user work.
- Summarize changed files, verification performed, and any checks that could not be run.
