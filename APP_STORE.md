# App Store checklist: Get Cracking (iPhone)

Your click-by-click list for shipping the iPhone app as a **free download with one A$5.99 unlock, The Whole Nest**. The plan and the reasons behind it are in `MONETIZATION.md`. Do the steps in order; each one says where in Xcode or App Store Connect (ASC) it happens.

Facts you'll need:

| | |
|---|---|
| App name | Get Cracking |
| Bundle ID | `com.glorptraag.getcracking` |
| Product ID | `com.glorptraag.getcracking.wholenest` |
| Product type | Non-Consumable |
| Reference name | The Whole Nest |
| Price | A$5.99, Australia as the base storefront |
| Family Sharing | On (can never be turned off again) |
| Devices | iPhone only, portrait, iOS 17+ |
| Category | Kids, Ages 5 and Under |

Placeholders still in the app (search `LegalLinks` in `GetCracking/Monetization/ProductID.swift`):
- `LegalLinks.privacyPolicy` = `https://getcrackingkids.vercel.app/privacy.html`: the policy now ships with the web app (`privacy.html`, Glorptraag/Get-Cracking#9). Once #9 is merged and deployed, **open that link to check it works**. If your production domain is different, change it here and in App Store Connect.
- `LegalLinks.terms` = Apple's standard EULA → fine as it is; replace only if you host your own terms.

---

## 1. Agreements, tax and banking (ASC, once)
1. ASC → **Business** (top bar) → **Agreements**. Accept the **Paid Apps Agreement**. Without it the purchase fails in review and the app is rejected.
2. Same page → **Tax Forms**: fill in the Australian tax form (and the U.S. W-8BEN form, which Apple asks every non-U.S. developer for).
3. Same page → **Bank Accounts**: add the account the proceeds go to.
4. Wait until the Paid Apps Agreement shows **Active** (can take a day or two).

## 2. Small Business Program (once)
1. Go to developer.apple.com/app-store/small-business-program and **Enroll** with the same Apple Account as the developer team.
2. Commission drops from 30% to 15%. At A$5.99 that is about **A$4.63 per sale** instead of A$3.81.

## 3. Create the in-app purchase (ASC)
1. ASC → **Apps** → Get Cracking (create the app record first if needed: **+** → New App → iOS, name "Get Cracking", primary language English (Australia), bundle ID `com.glorptraag.getcracking`, SKU e.g. `getcracking-ios`).
2. Left sidebar → **Monetization** → **In-App Purchases** → **+**.
3. Type: **Non-Consumable**. Reference Name: `The Whole Nest`. Product ID: `com.glorptraag.getcracking.wholenest` (exactly; it can never be reused or renamed). **Create**.
4. **Availability**: all countries or regions (or start with Australia only).
5. **Price Schedule** → **Add Pricing** → Base Country or Region: **Australia** → price **A$5.99**. Let Apple fill the other storefronts automatically. Confirm.
6. **Family Sharing**: **Turn On**. Read the warning: it can't be undone. (On purpose: the paywall tells parents it's on.)
7. **App Store Localization** → **Add Localization** → English (Australia) and English (U.S.):
   - Display Name: `The Whole Nest`
   - Description (max 55 characters): `Every friend, world and song, plus every new pack.` (50)
8. **Review Information**:
   - Screenshot: a screenshot of the paywall (step 9 below shows how to reach it in the simulator). At least 640×920 px.
   - Review Notes: paste the "App Review notes" from section 10.
9. Status becomes **Ready to Submit**. It is submitted together with the app version (section 11); a first IAP can't go in on its own.
10. Optional, but say no for now: **Promote in-app purchase** on the App Store page. Promoted purchases skip the in-app parental gate, so leave it off in the Kids Category.

## 4. StoreKit configuration file for local testing (Xcode)
Don't copy a `.storekit` file from anywhere; let Xcode write it.
1. Xcode → **File → New → File from Template…** → iOS → **StoreKit Configuration File** → Next.
2. Name `Products`, save it in the repo's **`Config/`** folder (not inside `GetCracking/`, so it never ships in the app). Leave "Sync this file with an app in App Store Connect" **unticked** for now (you can tick it later, once the IAP exists in ASC, to pull it in automatically).
3. In the editor: **+** (bottom left) → **Add Non-Consumable In-App Purchase**.
   - Reference Name: `The Whole Nest`
   - Product ID: `com.glorptraag.getcracking.wholenest`
   - Price: `5.99`
   - Family Shareable: **ticked**
   - Localization: Display Name `The Whole Nest`, Description `Every friend, world and song, plus every new pack.`
4. **Editor → Default Storefront → Australia** (and **Editor → Default Localization → English (Australia)**), so the paywall shows A$5.99.
5. **Product → Scheme → Edit Scheme…** → **Run** → **Options** → **StoreKit Configuration** → `Products.storekit`. Close.
6. Run in the simulator. Settings (⚙️) → The Whole Nest → answer the gate → the paywall shows **A$5.99**. Buy it; locks disappear; the friend book banner goes away.
7. To undo a test purchase: **Debug → StoreKit → Manage Transactions…** → select it → **Delete** (or **Refund** to test the downgrade rule).

## 5. Kids Category and age rating (ASC → App Information)
1. **Category**: Primary **Kids**, age band **Ages 5 and Under**. (Secondary: Education is optional; leave blank unless you want it.)
2. **Age Rating** → Edit. Answer:
   - All content descriptors (violence, horror, mature themes, profanity, alcohol/tobacco/drugs, gambling, sexual content, medical, contests): **None / No**
   - Unrestricted web access: **No**
   - User-generated content shared with others: **No** (photo friends stay on the device)
   - Messaging and chat: **No**
   - Advertising: **No**
   - In-app purchases: **Yes**
   - Parental controls / age assurance: **No**
   - Result should be **4+**.
3. Kids Category rules this app already meets, and must keep meeting forever (even if the category changes later):
   - No third-party analytics, ads or tracking. (`MonetizationLog` writes to the device log only.)
   - Purchases, Restore, Terms and Privacy links all sit behind the parental gate.
   - No links out of the app anywhere else; no push notifications.

## 6. App Privacy (ASC → App Privacy)
1. **Get Started** → "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app**. Publish. The label reads **Data Not Collected**.
2. This agrees with `GetCracking/Resources/PrivacyInfo.xcprivacy` (checked on this branch): `NSPrivacyTracking` false, no tracking domains, **no collected data types**, and one required-reason API (UserDefaults, reason `CA92.1`: the app's own settings and friend book). Nothing to change.
3. Why it's true: no accounts, no network code, no SDKs. Photos are picked with Apple's photo picker (no photo-library permission is asked) and saved as small JPEGs in the app's own folder; they never leave the device except inside the family's own iPhone backup. Purchases go through Apple; the app only reads StoreKit's signed receipts on the device.
4. **Privacy Policy URL**: `https://getcrackingkids.vercel.app/privacy.html` (the same as `LegalLinks.privacyPolicy`).

## 7. Draft privacy policy and terms (host them yourself)
The privacy policy is already written and hosted with the web app as `privacy.html`. It names the maker as Glorptraag, and points questions to the GitHub project's issues page. Change those two lines if you'd rather use a business name or an email address. The draft below is kept for reference.

### Privacy Policy (draft)
> **Get Cracking: Privacy Policy**
> Last updated: [date]
>
> Get Cracking is made by [your name or business name], [city, Australia]. Contact: [email address].
>
> **The short version: we don't collect anything.**
>
> - **No data collection.** Get Cracking has no accounts, no sign-in, no analytics, no advertising and no tracking. It does not send any information about you, your child or your device to us or to anyone else.
> - **Photos stay on your device.** If you add photo friends, you choose them with Apple's photo picker. The app keeps a small copy inside its own storage on your iPhone. They are never uploaded. They are included in your own iCloud or computer backup of the device, like any app data. You can remove them in the app at any time, or delete the app to remove everything.
> - **Settings and the friend book** are stored only on your device.
> - **Purchases** are handled entirely by Apple through the App Store. We never see your name, Apple Account or payment details. The app only checks with Apple, on the device, whether The Whole Nest has been bought.
> - **Children.** Get Cracking is made for children aged 5 and under and is in the App Store's Kids Category. Purchases and links are behind a parental gate. We do not knowingly collect any personal information from anyone, including children.
> - **Changes.** If this policy changes, we'll update this page and the date above.
>
> Questions: [email address].

### Terms of Use (draft, optional)
The app links to Apple's standard licence agreement by default, which is enough for App Review. If you'd rather host your own:
> **Get Cracking: Terms of Use**
> Last updated: [date]
>
> Get Cracking is licensed to you under Apple's Licensed Application End User License Agreement (https://www.apple.com/legal/internet-services/itunes/dev/stdeula/), together with these terms. [Your name or business name], [contact email].
>
> - **The Whole Nest** is a one-time in-app purchase. It unlocks every friend, world and hatching song in the app, unlimited photo friends, and every content pack we add to the app later, for as long as we offer the app. It is not a subscription and there is nothing more to pay.
> - **Family Sharing** is on: members of your Apple Family Sharing group can use The Whole Nest too.
> - **Refunds** are handled by Apple (reportaproblem.apple.com). If a purchase is refunded, the extra content locks again; photos you added and friends already found stay.
> - The app is provided "as is". It is a visual timer to help with routines, not a safety or medical device.
> - Nothing in these terms limits your rights under the Australian Consumer Law.

## 8. App Store page text (drafts)
Kids Category wording rules: the words "for kids" and "for children" are fine here because the app is in the Kids Category; don't name other brands, don't claim it's "educational" or "the best", don't mention prices in the screenshots or description in a way that targets children, and describe the purchase plainly to parents.

**Name** (30 max): `Get Cracking`

**Subtitle** (30 max): `Egg timer that hatches friends` (30)

**Keywords** (100 max, commas, no spaces): `toddler,visual timer,countdown,preschool,routine,transition,tidy up,bedtime,hatch,animal,band,kids` (98)

**Promotional text** (170 max, can change any time without review):
`New: Aussie Bush and Christmas packs! The Whole Nest unlocks all 65 friends, 13 worlds and every song, plus every new pack. The timer and 12 friends stay free.` (159)

**Description:**
```
A wordless timer for little ones. Set the time and watch the egg crack bit by bit as the minutes pass. When time's up, the egg hatches into a chibi animal friend who sings along with a little band, in its own voice.

Made for toddlers who can't read a clock yet: "when the egg hatches" is something they can see, hear and wait for. Use it for tidy-up time, teeth, screen time, turn-taking, bath time or bedtime.

FREE, FOREVER
• The full timer, from 10 seconds to 60 minutes
• 12 friends to hatch: chick, duckling, bunny, kitten, puppy, piglet, fox, owl, frog, penguin, elephant and dino
• 3 worlds: Sunny Meadow, Mossy Forest and Lily Pond
• Egg karaoke: the friend who hatched sings its own song with a little band
• Three hatch styles, gentle countdown music, the Animal band and four short hatching jingles
• One photo friend: a photo of someone they love can hatch from the egg
• A friend book that fills up as friends hatch
• A "Next up" card that shows what happens after the timer
• Grown-up controls behind a press-and-hold lock, so little fingers can't stop the timer

THE WHOLE NEST (one-time in-app purchase)
For families who want more:
• All 65 friends, including the dragon, unicorn, panda and capybara
• The Aussie Bush pack: a galah, mole cricket, joey, wombat, platypus and more, with an outback and a billabong
• The Christmas pack: gingerbread, the Nutcracker, a reindeer, a snowman and more, in a snowy Christmas village with sleigh bells
• All 13 worlds, from Snowy Pines to the Coral Reef Tank
• Every hatching song, with the Jungle jam and Farmyard hoedown bands
• As many photo friends as you like
• Every new pack of friends and worlds as it arrives, at no extra cost
One payment, no subscription. Family Sharing is on. Purchases sit behind a parental gate.

PRIVATE BY DESIGN
No ads. No accounts. No tracking. No data collected. Photos stay on your device. Works fully offline.
```

## 9. Screenshots
iPhone only (`TARGETED_DEVICE_FAMILY = 1`), so **no iPad screenshots** are needed; the app runs on iPad in iPhone mode.

Sizes: **6.9"** (1320 × 2868, iPhone 16 Pro Max simulator) is required; **6.5"** (1284 × 2778 or 1242 × 2688, iPhone 11 Pro Max / XS Max simulator) is optional but asked for here so older listings look right. Portrait. Up to 10 each; 5 is plenty.

Take them in the simulator with **File → Save Screen** (⌘S). Suggested set, in order:
1. The egg mid-crack in the Sunny Meadow with the ring half empty (caption: "A timer they can see")
2. A friend just hatched with "It's a Fox!" (caption: "Then a friend hatches")
3. The setup screen with the egg-timer dial (caption: "Twist to set the time")
4. The friend book with some friends found (caption: "Collect every friend")
5. The world picker showing several worlds (caption: "13 worlds, 65 friends with The Whole Nest")

Keep prices and buy buttons out of the screenshots (Kids Category). Use only free content in shots 1-4 if you'd like the page to match exactly what a new download sees.

## 10. App Review notes
Paste into **App Review Information → Notes** (app version) and the IAP's **Review Notes**:
```
Get Cracking is a wordless visual timer for children aged 5 and under (Kids Category). No account or sign-in is needed, and the app makes no network requests of its own.

In-app purchase: "The Whole Nest" (com.glorptraag.getcracking.wholenest), a Non-Consumable that unlocks all 65 friends (the Classic 40 plus the Aussie Bush and Christmas packs), 13 worlds, every hatching song, unlimited photo friends and future content packs. The free tier (the full timer, 12 friends, 3 worlds, Egg karaoke, the first animal band and jingles, one photo friend) is complete on its own.

Parental gate: every purchase surface, Restore Purchases, and the Terms of Use / Privacy Policy links are behind a parental gate that shows two numbers written as words (for example "nineteen plus twenty-three") and asks for the answer in digits (42). A wrong answer shows a new question. Children only ever see a small lock icon; there are no interruptive paywalls and nothing is shown on the timer screen.

To reach the purchase:
1. On the home screen tap the gear button (Settings).
2. The top row is "The Whole Nest". Tap it.
3. Answer the parental gate.
4. The paywall shows the price, Restore Purchases, Terms of Use and Privacy Policy. Tap "Unlock The Whole Nest".
Other ways in: tap a locked world (World button), a locked hatching song (Music button), a locked friend or the "For grown-ups" banner in the friend book (Friends button), or the locked "+" after adding one photo (Settings → Who hatches?).

After purchase every lock disappears. Restore Purchases is on the paywall only (Settings → The Whole Nest → parental gate), so it is never reachable without the gate.
```

## 11. Submit
1. Xcode: set your **Team** (Signing & Capabilities), bump **Version** / **Build**, **Product → Archive** → **Distribute App** → App Store Connect.
2. ASC → the app version → **Build**: pick it. Under **In-App Purchases and Subscriptions**, tick **The Whole Nest** so it goes in with this version.
3. Fill in screenshots, text, support URL (any page with your contact email), Privacy Policy URL, age rating, Kids Category.
4. **Add for Review** → **Submit**.

## 12. TestFlight / sandbox test script
Do this on a real iPhone before submitting. TestFlight builds use the sandbox, so nothing is really charged.

| # | Test | How | Expected |
|---|---|---|---|
| 1 | Free tier | Fresh install, no purchase | 12 friends hatch (never a locked one), worlds shuffle between Meadow, Forest, Pond; locked worlds/songs/friends show a small lock; nothing on the timer screen mentions buying |
| 2 | Gate | Settings → The Whole Nest; type a wrong answer, then the right one | Wrong: new question. Right: the paywall |
| 3 | Load failure | Airplane mode, open the paywall | "Couldn't reach the App Store just now" + Try again; nothing unlocks |
| 4 | Purchase | Online, Unlock The Whole Nest, confirm with the sandbox account | Paywall says thank you; every lock gone; friend-book banner gone; Settings row says "unlocked" |
| 5 | Shuffle | Run a few short timers | Locked-before friends and worlds now appear |
| 6 | Restore | Delete the app, reinstall, Settings → The Whole Nest → gate → Restore Purchases | Unlocks again |
| 7 | Offline launch | Owned; airplane mode; force-quit; relaunch | Still unlocked (StoreKit's receipts are on the device) |
| 8 | Ask to Buy | In Xcode with `Products.storekit`: **Editor → Enable Ask To Buy**, buy | "Waiting for a grown-up to approve"; approve in **Debug → StoreKit → Manage Transactions** → everything unlocks by itself |
| 9 | Refund / downgrade | Xcode Transaction Manager → **Refund** the purchase, return to the app | Locks come back; extra photos stay and still hatch; friends already found stay in the book; a locked world/song setting plays Surprise me / Egg karaoke |
| 10 | Family Sharing | After release (sandbox can't fully simulate it): a family member installs from the App Store, opens Settings → The Whole Nest → gate → Restore Purchases | Unlocked without paying |
| 11 | Foreground refresh | Refund in Transaction Manager while the app is in the background, then bring it back | Locks return without a relaunch |

Sandbox account: ASC → **Users and Access** → **Sandbox** → **Test Accounts** → **+**, Australian storefront. On the iPhone: **Settings → Developer → Sandbox Apple Account** (or Settings → App Store → Sandbox Account, depending on iOS version).

---

## Parity gaps before launch
What the web app (`main`) has that the iPhone app doesn't yet, from `.parity/PARITY.md` and `git log origin/ios-swiftui..origin/main`. Decide which must ship in 1.0; the rest can follow (every update is also a reason for parents to look at the app again).

| Web feature | Web commit(s) | iPhone today | Suggestion |
|---|---|---|---|
| **Egg karaoke**: the hatched friend sings its own song, in its own key, with a full band (now the web's default hatching song) | 464ee4e, c16c242, d0bb03b, 6364d23, 0fbc670 | **Ported** (parity/to-mac-20261123-karaoke, merged here) | Free, and the default hatching song. Checked against the web in CI (Tests/KaraokeChecks); listen to it on a device before release. |
| **Egg-timer dial** setup screen (twist ring, −/+ hold-repeat) and plain Start button | 2f810aa | **Ported** (parity/to-mac-20261123-ui, merged here) | Done. |
| **Big centred clock** on the timer screen | 982859f | **Ported** | Done. |
| **Drawn icons** instead of emoji | 982859f | **Ported** | Done. |
| **Plain deepening cracks** (CRACK_W_BY_STEP) | 982859f | **Ported** | Done. |
| **Content packs: pack on/off toggles and pack-grouped friend book** | 8e30287 (session branch) | **Ported**: registry, gating, grouped friend book and per-pack toggles | Done. |
| **Aussie Bush and Christmas packs** | claude/epic-hypatia-3w52rk (Glorptraag/Get-Cracking#9) | **Ported** (parity/to-mac-20261123-packart and -karaoke, merged here): 25 friends, 3 worlds, every call, voice line and karaoke sound | Done. Both are part of The Whole Nest. |

Also fixed on this branch: the iPhone app on `ios-swiftui` did not compile (the audio port's module-wide `typealias Path` hid SwiftUI's `Path`). It is renamed `PitchPath`; the CI build on this branch is the first green compile of the app.
