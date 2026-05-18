# NU Sublets - wiki 

## Overview
NU Sublets is a Northwestern-only subletting platform for posting and discovering sublet listings. The MVP focuses on fast listing creation, trusted access via NU email, and simple discovery and contact.

## Goals & Outcomes
- Enable students to publish a complete sublet listing in under 5 minutes  
- Make it easy to find relevant listings via search and filters  
- Ensure community safety via @u.northwestern.edu email verification  
- Facilitate direct contact via phone (no in-app messaging)

## User Roles
- **Authenticated Student** (NU email required)
- **Guest** (limited browsing; must sign in to view contact info)

## Core User Flows
1. Sign up with NU email → verify → (optional) add phone  
2. Create listing → add details → upload photos → publish  
3. Browse/search → apply filters → view listing → reveal phone (auth required) → call/text  

## Functional Requirements

### Authentication
- Magic link sign-in restricted to @u.northwestern.edu  
- Block non-NU domains  
- Store verification status  
- Session management via secure cookies  
- Logout support  

### Listing Creation
- **Fields**
  - Location (address / near campus)
  - Living type (apartment / house / other)
  - Bedrooms
  - Bathrooms
  - Start date, end date
  - Monthly price (USD)
  - Utilities included (Y/N)
  - Description (optional)
  - Photos (1–10)
  - Contact phone (required)

- **Actions**
  - Save draft
  - Publish
  - Edit
  - Unpublish
  - Delete (owner only)

- **Photo Handling**
  - Client-side compression  
  - Max 10MB per image  
  - Accepted: JPG, PNG, HEIC  

### Search & Filtering
- Search by location keyword  
- Filters:
  - Living type
  - Bedrooms
  - Bathrooms
  - Date range (overlap with listing)
  - Price range
  - Utilities included  
- Sort:
  - Newest
  - Price (asc/desc)  
- Pagination or infinite scroll  

### Contact
- Phone number hidden until authenticated  
- Tap-to-call / tap-to-text (mobile)  
- No in-app messaging (MVP)  

### Link to Miro Board for OO Design
- link to Miro Board: [https://miro.com/app/board/uXjVHe33FBE=/?share_link_id=268751287521](https://miro.com/app/board/uXjVHe33FBE=/?share_link_id=268751287521)

## Data Model

### User
- id  
- name  
- nuEmail  
- phone  
- verified  
- createdAt  
- updatedAt  

### Listing
- id  
- ownerId  
- title (auto-generated: “{Bedrooms}BR {Type} in {Location}”)  
- location  
- type  
- bedrooms  
- bathrooms  
- startDate  
- endDate  
- monthlyPrice  
- utilitiesIncluded  
- description  
- photos (array of URLs)  
- status (draft / active / paused)  
- createdAt  
- updatedAt  

## Future Features
- In-app messaging  
- Saved listings / favorites  
- Notifications (new listings, price drops)  
- Reviews or verification signals  
- Map view  

## Similar Products
- [Airbnb](https://www.airbnb.com/)
- [Northwestern Off-Campus Housing](https://offcampushousing.northwestern.edu/)

## Visual Asset Sources
- NU Sublets logo and app icons: project-created assets in `app/assets/images` and `public`
- Apartment listing demo images: project assets in `app/assets/images`
- Campus/Evanston image: project asset `app/assets/images/nu-evanston.jpg`
- Generated initials avatars: [UI Avatars](https://ui-avatars.com/)
- Demo profile portraits used in seed/static listing cards: [Random User](https://randomuser.me/)

## Repository Notes
The repository includes a `wiki.md` file with additional project context, including:
- Problem description  
- Design references (e.g., Miro board)  
- Future feature ideas  
- Comparable platforms  

## Visual Improvements

### Header and Footer Navigation Icons
Added small decorative icons next to the main header navigation links (`Browse`, `Search`, `Saved`, and `Post Sublet`) and footer links (`About Us`, `Privacy Policy`, `Disclaimer`, and `GitHub Repository`). This improves visual polish, makes navigation easier to scan, and keeps the header/footer style consistent throughout the app.

Icon source: custom inline SVGs adapted from [Bootstrap Icons](https://icons.getbootstrap.com/) path data. Bootstrap Icons are open source under the [MIT License](https://github.com/twbs/icons/blob/main/LICENSE.md). Icons are used decoratively with visible text labels preserved for accessibility.

## JavaScript UX Improvements

### Post Sublet Photo Upload Preview + Validation
Added photo previews to the Post Sublet form so users can see selected listing photos before submitting. Added client-side warnings for selecting too many photos, unsupported file types, and oversized files.

- Too many photos warning: `You can upload up to 5 photos per listing.`
- File size warning: `Each photo must be 5 MB or smaller.`
- File type warning: `Photos must be PNG, JPG, or WebP files.`

Server-side validation remains the source of truth for all upload limits and allowed file rules.

### Post Sublet Description Character Counter
Added a live description character counter to the Post Sublet form so users get immediate feedback while typing (for example, `0 / 1000 characters`). The counter highlights when users are approaching the limit and shows a friendly warning if they exceed the maximum.

This improves form clarity and helps prevent overly long listing descriptions before submission. Server-side validation remains the source of truth.
