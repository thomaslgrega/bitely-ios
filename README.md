# Bitely (iOS)

Bitely is an offline-first iOS recipe app built with **SwiftUI + SwiftData**, with optional cloud sharing via a **Go + PostgreSQL** API.

- Browse recipes by category
- View recipe details (ingredients + instructions)
- Save recipes locally for offline use (SwiftData)
- Build a shopping list from ingredients
- Plan meals for the day using a calendar view
- Sign in to share recipes and manage your shared library

**Backend API repo:** [bitely-api](https://github.com/thomaslgrega/bitelyapi)

---

## Demo

- `Screenshots/saved-recipes.png`
- `Screenshots/recipe-detail.png`
- `Screenshots/shopping-list.png`
- `Screenshots/meal-planning.png`

---

## Tech Stack

- SwiftUI
- SwiftData (offline persistence)
- async/await networking
- DTO-based networking layer (separate API models vs SwiftData models)

---

## App Design

### Offline-first, login optional
Most features work without an account. Local recipes and shopping lists are stored on-device.

When signed in, users can also:
- Share recipes to the backend
- View / delete their shared recipes (server-side)

---

## Running Locally

### Configure API base URL
The app connects to the API at:
- Simulator: `http://localhost:8080`

### Run
1. Open the project in Xcode
2. Select a simulator device
3. Run ▶︎

---

## Roadmap

- Sign in with Apple (in progress)
- Image upload (AWS S3 or Cloudflare R2) for shared recipes (planned)
- Pagination + improved search
