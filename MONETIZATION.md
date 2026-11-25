# Monetization plan: Get Cracking (iPhone)
Mode: BUILD    Updated: 2026-11-23    Branch: `parity/to-mac-20261123-store`

The web app (`main`, Vercel) stays free in full. Everything here is the App Store iPhone app only.

## Model
Free download plus **one Non-Consumable unlock, The Whole Nest (A$5.99)**, that opens everything now in the app and every content pack added later. No subscription, no ads, no consumables.

Why:
- No ongoing cost per user: no servers, no accounts, photos stay on the device. `[Rule]` 3.1.2(a) allows subscriptions only for ongoing value, and a one-time price fits a bounded toy with occasional packs. `[Judgment]`
- The buyer is a parent; the user is a toddler. A single, clear, one-off purchase is the easiest thing for a parent to say yes to, and the easiest thing to explain in the Kids Category. `[Judgment]`
- Growth is word of mouth between families, so the free tier must be lovable on its own (freemium, Split architecture: the free tier is complete; the unlock adds more of everything). `[Judgment]`
- "Every future pack included" is the continuity promise without a continuity bill. It also protects early buyers from feeling nickel-and-dimed when the Aussie Bush and Christmas packs land. `[Judgment]`
- `[Rule]` 4.3(b) lists simple timers as a saturated category. Get Cracking is not a clone (a wordless visual timer whose egg hatches into a chibi friend who plays in a band), and the free tier keeps every bit of that difference. The unlock is more of the delight, never a tax on the timer.

## Offer
**Name:** The Whole Nest (MAGIC: the nest holds every egg and every friend; matches the App Store display name)

**Stack (what the grown-up gets):**
1. All 65 friends to hatch and collect in the friend book (53 more than free)
2. All 13 worlds (10 more)
3. Every hatching song, including the Jungle jam and Farmyard hoedown bands
4. As many photo friends as they like (grandparents, pets, the whole family)
5. Every pack of friends and worlds, now and as new ones arrive, at no extra cost (Aussie Bush and Christmas are in the app)

**Unsell line (on the paywall):** "The timer and 12 friends are free, forever. The Whole Nest is for families who want every friend, world and song, plus every new pack as it arrives."

**Risk reversal:** none beyond the truth: one payment, no subscription, Family Sharing on, Restore any time. No trial: the free tier already is the trial. `[Judgment]`

## Free vs premium
| Feature | Class | Free | The Whole Nest | Trigger | Basis |
|---|---|---|---|---|---|
| Timer (state machine, pause, ±1 min, tap-to-hatch, keep awake) | Core loop | Yes | Yes | n/a | `[Rule]` 4.2: the free tier stands alone |
| Every timer setting (presets, hold-to-open lock, show numbers, next-up card) | Core loop | Yes | Yes | n/a | `[Judgment]` Bill of Rights |
| Hatch styles (Roll away, Kaboom, Crumble) | Aha | All | All | n/a | `[Judgment]` the hatch is the aha |
| Countdown music (6 tracks) | Core | All | All | n/a | `[Judgment]` |
| Friends | Expansion | 12 starters: chick, duckling, bunny, kitten, puppy, piglet, fox, owl, frog, penguin, elephant, dino | All 65 | Locked tap in the friend book; friend-book banner | `[Judgment]` matches web `starter: true` |
| Worlds | Expansion | 3: Sunny Meadow, Mossy Forest, Lily Pond | All 10 | Locked tap in the world picker | `[Judgment]` matches web `starter: true` |
| Hatching songs | Expansion | Egg karaoke (the default) + Animal band + 4 jingles (Ta-da, Chimes, Birdsong, Bubbles) | + Jungle jam, Farmyard hoedown, every later band | Locked tap in the song picker | `[Judgment]` |
| Photo friends | Volume (taster) | 1 (live count: removing it frees the slot) | Unlimited | Locked "+" after one photo | `[Judgment]` |
| Content packs (Aussie Bush, Christmas, future) | Expansion | Not included (a pack can be marked `isFree`) | All, now and later | Pack friends and worlds show locks like Classic ones; a locked pack's toggle opens the gated paywall | `[Judgment]` owner decision |
| Friend book | Identity | Shows every friend; locked ones as silhouettes with a small lock | Same, no locks | n/a | `[Judgment]` never blank, never a pitch |

Implementation: `GetCracking/Monetization/FeatureGate.swift` (every decision), `Packs.swift` (the registry and starter flags), checked by `Tests/GateChecks/main.swift` in CI.

## Bill of Rights
Always free, never moved behind the unlock:
- The whole timer and every timer setting, hatch styles, countdown music.
- The 12 starter friends, 3 starter worlds, Egg karaoke, the first animal band and the short jingles, one photo friend.
- The friend book itself.

Downgrade rule (refund, or leaving a Family Sharing group):
- Photos the family added stay and keep hatching; only adding new ones is limited.
- Friends already found stay visible in the friend book.
- A setting that points at something locked plays the nearest free thing (a locked world plays as "Surprise me", a locked song plays Egg karaoke); the setting itself is kept so it comes back if they buy again.

Never, in any experiment:
- A pitch, price or upsell on a kid-facing screen. The child only ever sees a small lock.
- An interruptive paywall. Every placement is a grown-up tapping something.
- Purchases, Terms or Privacy reachable without the parental gate (numbers written as words). Restore Purchases buys nothing and sits in Settings ungated, as well as on the paywall.
- Fake countdowns, fake scarcity, invented "values", discount-on-dismiss, push notifications.
- Third-party analytics, ads or tracking (Kids Category). `MonetizationLog` writes to the device log only.
- Locking anything the family made.

## Products and prices
| Product ID | Reference name | Type | Price (base storefront Australia) | Intro offer | Family Sharing | Basis |
|---|---|---|---|---|---|---|
| `com.glorptraag.getcracking.wholenest` | The Whole Nest | Non-Consumable | A$5.99 (the A$5.99 price point; other storefronts follow Apple's equalisation) | None | On (irreversible) | `[Judgment]` owner decision; `[Rule]` Family Sharing can't be turned off once on |

Derived from the app's bundle id `com.belladouglas.getcracking` (`GetCracking.xcodeproj`).

Unit economics: A$5.99 includes 10% GST, so A$5.45 before tax; in the Small Business Program (15%) proceeds are about **A$4.63 per sale**. `[Rule]` prices include tax in Australia.

Price position: the skill's starting range for a casual-app unlock is US$4.99-9.99 `[Judgment]`; A$5.99 (about US$3.99) sits just under it, which suits a toddler toy bought on impulse by a parent. First price test: one tier up (A$7.99) after the first 100 sales. `[Judgment]`

No hand-written `.storekit` file: its JSON schema is undocumented and shifts between Xcode versions. The owner creates it in Xcode from the table above (APP_STORE.md, step 4).

## Placements
All user-initiated; all open the parental gate first, then the paywall (`PaywallPlacement` in `ParentalGate.swift`).

| Placement | Moment | Interruptive? | Notes |
|---|---|---|---|
| `settings` | Grown-up settings, top row "The Whole Nest" (what it includes, no price), with Restore Purchases under it | No | The menu is always on the table |
| `lockedWorld` | Tapping a locked world in the world picker | No | Lock badge on the card |
| `lockedSong` | Tapping a locked hatching song | No | 🔒 on the chip |
| `lockedFriend` | Tapping a locked silhouette in the friend book | No | Small lock badge |
| `friendBook` | Banner at the foot of the friend book: "For grown-ups: 28 more friends live in The Whole Nest." | No | One quiet line, addressed to the adult |
| `photoLimit` | The "+" after one photo friend | No | Locked "+" with a badge |

Not used, on purpose: onboarding paywall, post-win paywall, decline follow-up, purchase-success upsell. A toddler is on the timer screen; nothing ever interrupts it. `[Judgment]` (`[Data]` onboarding paywalls convert better, but not in a kids app where the child holds the phone.)

## Money model sequence
- **Attraction:** free goodwill. A complete, lovable timer with 12 friends, 3 worlds and a band. Word of mouth between parents.
- **Upsell:** one menu upsell (unsell line, 5 outcome bullets, one price) at the moment a grown-up reaches for more (a locked friend, world, song or second photo).
- **Downsell:** none at launch (one product only). If data says the price is the blocker, the trade is a single pack on its own, never the same thing cheaper. `[Judgment]`
- **Continuity:** every new pack arrives free for owners; each pack release is a reason for free users to look again (a locked friend in the book) and for owners to tell other parents.

## Hypotheses and tests
Small app, so: one change at a time, 2-4 weeks each, logged with its date below. Under about 100 purchases per variant, treat differences as noise. `[Judgment]`

| Hypothesis | Metric (App Store Connect) | Test | Status |
|---|---|---|---|
| 12 friends is enough to love and few enough to want more | Paying users / first-time downloads per weekly cohort | Watch weeks 1-4; if conversion < 1%, surface the friend-book banner earlier or drop to 10 starters | Planned |
| A$5.99 is below what parents would pay | Proceeds per download | After 100 sales, move to A$7.99 for 4 weeks | Planned |
| A new pack lifts conversion | Sales in the 2 weeks after a pack release vs the 2 weeks before | Release Aussie Bush, compare | Planned |
| One photo friend is the right taster | Not visible without analytics | Review App Store reviews mentioning photos | Planned |

The Kids Category rules out an analytics SDK, so the only numbers are App Store Connect's: downloads, sales by product, proceeds. `MonetizationLog` is for debugging on a device only.

## For you to do by hand (Xcode and App Store Connect)
The full click-by-click list is in `APP_STORE.md`. In short:
- [ ] Paid Apps Agreement, tax and banking; Small Business Program
- [ ] Create the Non-Consumable `com.glorptraag.getcracking.wholenest`, A$5.99, Australia as base, Family Sharing on, review screenshot and notes; submit it with the app version
- [ ] Create `Products.storekit` in Xcode and select it in the scheme to test locally
- [ ] Host the privacy policy (and terms if you want your own) and replace `LegalLinks` in `ProductID.swift`
- [ ] Kids Category (5 and under), age rating, App Privacy "Data Not Collected"
- [ ] Sandbox / TestFlight: purchase, restore, Ask to Buy, Family Sharing, offline launch

## Assumptions made without asking
- The app has not shipped, so there is nobody to grandfather. If a paid or free build ever shipped with all 40 friends, add `AppTransaction` grandfathering before release.
- Terms of Use link uses Apple's standard EULA until you host your own.
- The paywall promises "every new pack as it arrives". Aussie Bush and Christmas are in the app, so the App Store description now names them; never name a pack before it ships.
- Pack on/off toggles (web `S.packsOff`) are not ported yet; with only Classic on the iPhone there is nothing to toggle.
- No test target exists and the project is not hand-edited, so the gate checks run as a small `swiftc` program in CI instead of XCTest.
- iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait.

## Change log
| Date | Change | Result |
|---|---|---|
| 2026-11-23 | The Whole Nest built (StoreKit 2, parental gate, pack registry, locks, CI) | Awaiting owner review |
