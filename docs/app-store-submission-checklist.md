# PokerSpot — App Store / Play Store გასაშვები checklist

> მიზანი: native iOS/Android-ზე გადასვლისას rejection-ის თავიდან აცილება.
> ეს პოკერ-აპია → ყველაზე დიდი რისკი azartul თამაშებთან დაკავშირებული წესებია.

---

## ⚠️ #1 — Gambling წესი (Apple Guideline 5.3) — მთავარი რისკი

Apple/Google პოკერ/კაზინო-თემატიკას მკაცრად ამოწმებენ. გადამწყვეტია პოზიციონირება:

- აპი = **venue / floor management tool** (waitlist, დასხდომა, ტურნირები ფიზიკურ კლუბებში) — **არა real-money gambling**
- აპში **არ ხდება**: ფულზე თამაში, ფსონი, ჩიპები, ფულადი ტრანზაქცია, IAP თამაშისთვის
- review notes-სა და აღწერაში მკაფიოდ ითქვას: "no real-money gaming in the app"
- ⚠️ თუ სადმე ნამდვილ ფულთან კავშირი გაჩნდა → საჭიროა gambling ლიცენზია + გეო-შეზღუდვა + უფასო აპი (5.3.4)

---

## 🔒 #2 — სავალდებულო (ამის გარეშე ავტომატური reject)

- [ ] **Account deletion აპში** (Apple 5.1.1(v), Google-იც) — ანგარიში აპიდანვე უნდა იშლებოდეს. cascade-ით უნდა წაიშალოს/ანონიმდეს sessions/waitlist/reservations/registrations/messages/fcmTokens. **ჯერ არ გვაქვს.**
- [ ] **Demo ანგარიში reviewer-ისთვის** (2.1) — Apple-ის შემმოწმებელი SMS-ს ვერ მიიღებს. გასაკეთებელია **Firebase test phone number** (Console → Authentication → Phone → Phone numbers for testing): ფიქსირებული ნომერი + ფიქსირებული OTP. review notes-ში მიეცი.
- [ ] **Privacy policy URL** — public გვერდი (იხ. #3)
- [ ] **App Privacy labels** App Store Connect-ში (იხ. #3)
- [ ] **Permission config** iOS-ზე — push capability + APNs (იხ. #4)
- [ ] **Age rating 17+** (პოკერ-თემატიკა)

---

## ✅ #3 — Privacy Policy URL + App Privacy Labels (დეტალურად)

### (ა) Privacy Policy URL
Public ვებ-გვერდი, რომელიც აღწერს მონაცემთა დამუშავებას. App Store Connect-სა და Play Console-ში შეჰყავ URL — **ორივე store სავალდებულოდ ითხოვს** ნებისმიერი აპისთვის, რომელიც მონაცემს აგროვებს.

უნდა შეიცავდეს PokerSpot-ისთვის:
- **რა მონაცემს ვაგროვებთ:** ტელეფონის ნომერი, სახელი/გვარი, ენა, თამაშის აქტივობა (რომელ კლუბში/მაგიდაზე/როდის), waitlist/reservation/tournament ჩანაწერები, push token (მოწყობილობის ID)
- **რატომ** (lawful basis) — სერვისის მუშაობა
- **ვის ვუზიარებთ** — Google Firebase (processor); transfer/რეგიონი
- **შენახვის ვადა** (retention)
- **მომხმარებლის უფლებები** — წვდომა, წაშლა, ექსპორტი; როგორ წაშალოს ანგარიში
- **კონტაქტი** (data controller)

**სად განვათავსოთ:** ყველაზე მარტივი — Firebase Hosting-ზე, მაგ. `https://pokerspot.web.app/privacy` (ცალკე `privacy.html` ან route). უფასოა, უკვე გვაქვს hosting.

### (ბ) App Privacy Labels ("nutrition label")
App Store Connect-ში submit-მდე ავსებ კითხვარს — რა მონაცემს აგროვებ, linked to identity თუ არა, tracking-ისთვის თუ არა. Apple ამას აჩვენებs აპის გვერდზე "App Privacy" სექციად.

PokerSpot-ისთვის სავარაუდო დეკლარაცია:
| Data type | Linked to user? | Tracking? | Purpose |
|---|---|---|---|
| Contact Info → Phone | ✅ კი | ❌ არა | App Functionality / Account |
| Contact Info → Name | ✅ კი | ❌ არა | App Functionality |
| Identifiers → User ID (uid) | ✅ კი | ❌ არა | App Functionality |
| Usage Data (თამაშის აქტივობა) | ✅ კი | ❌ არა | App Functionality |
| Device ID (push/FCM token) | ✅ კი | ❌ არა | Push notifications |

- **Tracking = NO** (არ ვაკეთებთ რეკლამას/cross-app tracking → ATT/IDFA არ გვჭირდება)
- ⚠️ **labels უნდა ემთხვეოდეს** რეალურ ქცევას + privacy policy-ს. შეუსაბამობა → reject.
- Google Play-ს აქვს ანალოგი — "Data Safety form".

---

## ✅ #4 — iOS Permission config (Info.plist / capabilities) (დეტალურად)

### რა არის Info.plist purpose strings
iOS-ზე ყოველი მგრძნობიარე ნებართვისთვის (კამერა, ფოტო, ლოკაცია, მიკროფონი, კონტაქტები...) `Info.plist`-ში უნდა იყოს **`NS...UsageDescription`** ტექსტი — სისტემურ permission dialog-ში ჩანს ("რატომ სჭირდება"). **თუ ნებართვას ითხოვ ამ string-ის გარეშე → აპი crash-დება იმ მომენტში → Apple აჯექტებს.**

### PokerSpot-ისთვის რეალურად რა გვჭირდება
⚠️ მნიშვნელოვანი დაზუსტება: **push notifications-ს purpose string არ სჭირდება** — შეტყობინების permission dialog სტანდარტულია, custom ტექსტის გარეშე. push-ისთვის საჭიროა **capability + APNs**, არა Info.plist string:

- **Push Notifications capability** (Xcode → Signing & Capabilities → + Push Notifications) → entitlement `aps-environment`
- **Background Modes → Remote notifications** (თუ silent push გვინდა)
- **APNs Auth Key (.p8)** Apple Developer-ში → ატვირთე Firebase Console-ში (Cloud Messaging → Apple app config)
- `GoogleService-Info.plist` iOS-ისთვის Firebase-დან

ამჟამად აპი **კამერას/ფოტოს/ლოკაციას არ იყენებს** → purpose string-ები **არ გვჭირდება**.

თუ მომავალში დაემატება (მაგ. ავატარის ფოტო) → მაშინ:
- `NSCameraUsageDescription` — "Used to take your profile photo"
- `NSPhotoLibraryUsageDescription` — "Used to choose your profile photo"

ATT (`NSUserTrackingUsageDescription`) **არ გვჭირდება** — tracking/реклама არ გვაქვს.

### სხვა iOS Info.plist საბაზისო
- `CFBundleDisplayName` — აპის სახელი ეკრანზე
- `CFBundleIdentifier` — bundle id (მაგ. `com.pokerspot.app`)
- minimum iOS version

---

## 📋 პროცესი (მოკლედ)
1. App Store Connect → ახალი აპი → bundle id
2. screenshots (ყველა საჭირო ზომა) + აღწერა + keywords
3. App Privacy labels შევსება (#3ბ)
4. Privacy policy URL (#3ა)
5. Age rating questionnaire → 17+
6. build (Xcode ან Codemagic) → upload → TestFlight
7. Review notes: demo test phone+OTP + "venue management, no real-money gaming"
8. Submit for Review

---

## ✅ ნაკლები რისკი, მაგრამ შესამოწმებელი
- არ არის web-wrapper — native Flutter ✅ (4.2)
- სრული, უ-ბაგო, placeholder-ების გარეშე (2.1)
- Sign in with Apple **არ გვჭირდება** — phone OTP-ს ვიყენებთ, social login არ გვაქვს (4.8)
- push სავალდებულო არ უნდა იყოს აპის სამუშაოდ
