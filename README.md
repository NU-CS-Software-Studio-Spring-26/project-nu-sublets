# NU Sublets

## **Project Board**

**We were not able to create a GitHub Project Board directly under the `NU-CS-Software-Studio-Spring-26` classroom organization, so we are using the following project board for now:**

**[NU Sublets Project Board](https://github.com/users/melindajwang/projects/1)**

### An .edu-verified marketplace where students post and browse sublets.

NU Sublets is a Rails application designed to help Northwestern students safely post, search, and browse sublet listings. The app supports authenticated student users, listing creation, listing photos, search/filter/sort tools, favorites, and basic safety restrictions around contact information and listing ownership.

## MVP

For our MVP, we need a platform for people to post their living spaces for subletting. Supported features should include searching or listing sublets by location, living arrangement (apartment with X bedrooms and Y bathrooms, house, etc.), duration of sublet, price per month including utilities, photos, etc. People looking to sublet should be able to filter by these features when searching and browsing for options. The platform should require authenticated login for safety reasons (maybe need u.northwestern.edu login). Also there could be some basic chat functionality, maybe as simple (at first) as space to provide phone numbers so subletters can get in contact and negotiate.

## Current App Capabilities

- Create an account and log in with Northwestern student email restrictions.
- Log out securely with flash notifications.
- Browse available sublet listings.
- Search listings by location.
- Filter listings by price, beds, baths, housing type, and lease duration.
- Sort listings by newest and price.
- Create sublet listings as an authenticated user.
- Add listing photos and display uploaded photos.
- Add richer listing details, including utilities, furnished status, roommates, amenities, availability dates, lease duration, and contact information.
- Hide contact information unless the viewer is logged in.
- Save/favorite listings.
- View user profile and saved/favorited listings.
- Prevent users from editing, updating, or deleting listings they do not own.
- Display empty states and no-results states where appropriate.
- Seed the database with realistic demo data.
- Run model, controller, system, authentication, and authorization tests.

## Listing Photo Upload Rules

Listing photos are validated server-side. Each listing can have up to 5 photos, and each photo must be a PNG, JPG, or WebP file that is 5 MB or smaller.

## Team Members / Contributors

- Melinda Wang
- Ryan Murphy
- Katelyn Cai
- Shun Fujita

## Deployment

Heroku deployment link:

https://nu-sublets-02a3e969c37a.herokuapp.com/

Miro project management board:

https://miro.com/app/board/uXjVHe33FBE=/

## Communication

- Meet on Sundays in person from 2 p.m. to 6 p.m. for weekly updates and task completion.
- Use iMessage for the main method of communication outside of class and meeting times.
- Respond timely (< 24 hours) to any chats or texts if the message pertains to your responsibilities, tasks, etc.
- Communicate conflicts in advance (at least 12 hours in advance), for example, if you cannot make a meeting or class.
- Democratic voting process for important decisions, flip a coin for a tie.

## Team Workflow

- Project tasks are tracked through the team project board.
- Tasks in the current sprint and done columns should be assigned to team members.
- Each major feature should be developed on a branch when possible.
- Pull requests should be reviewed by at least one teammate when possible before merging.
- Commit messages should be meaningful and describe the change being made.
- The GitHub repository should reflect the current state of the project.
- Dormant branches should be cleaned up or left inactive; the team should keep no more than four active branches at a time when possible.

## Repository Layout

- `app/models`: Rails models, including users, listings, favorites, and related application data.
- `app/controllers`: Rails controllers for handling user flows, listings, sessions, pages, and related requests.
- `app/views`: ERB views and partials for the public-facing UI.
- `app/assets`: Stylesheets, images, and front-end assets.
- `config`: Rails routes, environment configuration, and application settings.
- `db`: Database schema, migrations, and seed data.
- `test`: Automated tests for models, controllers, system behavior, authentication, authorization, and search/filter functionality.
- `.github/workflows`: GitHub Actions / CI configuration, if present.
- `CHANGELOG.md`: Release notes for tagged milestone versions.

## Getting Started

From the repository root, install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Seed demo data:

```bash
bin/rails db:seed
```

Start the Rails server:

```bash
bin/rails server
```

Then open:

```text
http://127.0.0.1:3000
```

If a Rails server is already running, remove the stale PID file or stop the existing process:

```bash
rm tmp/pids/server.pid
bin/rails server
```

## Ruby / Rails Version

This project uses the Ruby version specified in `.ruby-version`.

To make sure your local Ruby version matches the project:

```bash
ruby --version
cat .ruby-version
```

If using `rbenv`:

```bash
rbenv install
rbenv local 4.0.2
rbenv rehash
```

## Environment Notes

- Secrets and sensitive configuration should be stored in environment variables, not committed to the repository.
- Local environment files such as `.env` should not be pushed to GitHub.
- Production should not expose raw stack traces to users.
- The app is deployed on Heroku.

## Authentication

NU Sublets supports local email/password authentication and Google OAuth for Northwestern-verified users.

Local authentication:

- Users can sign up with name, Northwestern email, password, and password confirmation.
- Passwords are handled through Rails `has_secure_password`.
- Raw passwords are never stored. The database stores only the BCrypt-backed `password_digest`.
- Local login failures use a generic error message so the app does not reveal whether a specific email address exists.
- Email addresses must belong to an allowed Northwestern domain.

Google OAuth authentication:

- Google login is handled through OmniAuth and `omniauth-google-oauth2`.
- Successful OAuth login reads the Google auth hash email, uid, provider, and name.
- The app only creates or logs in users whose Google email passes the Northwestern domain check.
- Existing users are matched by Google provider/uid or by email so repeat OAuth login does not duplicate accounts.

Required OAuth environment variables:

```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

In the Google Cloud Console, add this authorized redirect URI for local development:

```text
http://localhost:3000/auth/google_oauth2/callback
```

For deployed environments, add the same callback path on the production host, for example:

```text
https://your-production-host/auth/google_oauth2/callback
```

If Google returns `Error 400: invalid_request`, check that both environment variables are present and that the exact callback URL for the host you are using is listed in the OAuth client settings.

OAuth credentials and local `.env` files must not be committed to the repository.

## Testing

Run the test suite with:

```bash
bin/rails test
```

The test suite includes or should include coverage for:

- Model validations and associations.
- Search and filter behavior.
- Authentication-protected routes.
- Permission checks for listing ownership.
- Happy-path user flows where possible.

## PWA Support

NU Sublets includes a web app manifest and a conservative service worker for installability. The service worker caches only static/public assets and avoids authenticated, user-specific, form-submission, listing-detail, and account pages.

The installed app icons are generated from the existing NU Sublets logo and served from `public/icons/`.

To test installability, open Chrome DevTools and inspect:

- Application -> Manifest
- Application -> Service Workers

On Android Chrome, users can choose "Add to Home screen." On iPhone Safari, users can use Share -> Add to Home Screen.

The deployed Heroku app should be tested over HTTPS because service workers and installability require a secure context outside localhost.

## Linting / Code Quality

Run the Rails/Ruby linter with:

```bash
bundle exec rubocop
```

or, if configured:

```bash
bin/rubocop
```

Run Rails security scanning with Brakeman:

```bash
bundle exec brakeman --no-pager
```

Brakeman runs in GitHub Actions CI on both pushes and pull requests as part of the security scan job.

Code quality expectations:

- Linters should be applied before milestone submission.
- Non-functional, unused, or commented-out code should be removed.
- Debugging code such as `puts`, `binding.irb`, or temporary console logs should be removed.
- Meaningful comments should be included where logic is not immediately obvious.
- Repeated view logic should be refactored into partials where appropriate.
- Code should stay DRY and readable.

## Documentation

- Project overview: `README.md`
- Release notes: `CHANGELOG.md`
- Database setup and demo data: `db/seeds.rb`
- Tests: `test/`
- CI configuration: `.github/workflows/`, if present

## Releases

Milestone release versions are tracked with annotated Git tags.

Current release:

- `v0.1.0` — Milestone 1 MVP release

The corresponding release notes are documented in `CHANGELOG.md`.
