# TLN Hours

A macOS menu bar app that shows your arrival time and a countdown to your
8h/8h30 work targets, driven by a Home Assistant `person` entity's
zone-tracking.

## Opening the app for the first time

TLN Hours isn't signed with an Apple Developer ID, so macOS Gatekeeper will
block it as "unidentified developer" the first time you open it. After
dragging it to Applications:

- Right-click (or Control-click) `TLNHours.app` → **Open** → **Open** in the
  dialog, or
- Run `xattr -cr /Applications/TLNHours.app` once in Terminal to clear the
  quarantine flag.

After that first launch, it opens normally like any other app.

## How it works

The app polls a `person.*` entity in your Home Assistant instance once a
minute. When that person's `state` becomes `Work` (i.e. their phone enters a
zone named exactly **Work**), the app treats them as arrived and counts up
from that moment toward the 8h and 8h30 targets. When the state leaves
`Work`, it goes back to "away".

Everything below happens in your own Home Assistant instance — nothing is
shared between different people's setups.

## 1. Set up Home Assistant

### Create the "Work" zone

In Home Assistant: **Settings → Areas, Labels & Zones → Zones → Add Zone**

- Name: `Work` (must be exactly this — the app matches the zone name
  literally, case-sensitive)
- Location/radius: your workplace, sized to comfortably cover the building
  and parking (e.g. ~150–200m)
- Icon: whatever you like (e.g. `mdi:briefcase`)

### Make sure you're being location-tracked

Your `person.*` entity needs a device tracker reporting GPS location — the
Home Assistant Companion App on your phone does this automatically once
you're logged in and have granted location permission (**Settings → People**
to confirm your person entity is linked to your phone).

Once that's in place, HA handles the rest natively: your person entity's
state automatically switches to `Work` when you're inside the zone, and back
to `home`/`not_home` when you leave. No automation is required for this
part.

### Create a long-lived access token

**Profile (bottom left) → Security → Long-Lived Access Tokens → Create
Token.** Copy it immediately — it's only shown once. This is what the app
uses to authenticate; treat it like a password.

### Optional: arrival/leave notifications

The app itself doesn't need these — it computes everything locally from the
zone state. But if you'd like a Telegram (or other) message on arrival and
departure, mirroring what the app shows, here's an example pair of
automations. Adjust the `entity_id` and notify target to your own:

```yaml
# Sent when you enter the Work zone
- alias: Notify when I arrive at work
  triggers:
    - trigger: state
      entity_id: person.YOUR_NAME
      to: "Work"
  actions:
    - action: notify.send_message
      target:
        entity_id: notify.YOUR_NOTIFY_SERVICE
      data:
        message: >-
          Arrived at {{ now().strftime('%H:%M') }} - leave at
          {{ (now() + timedelta(hours=8)).strftime('%H:%M') }} //
          {{ (now() + timedelta(hours=8, minutes=30)).strftime('%H:%M') }}

# Sent when you leave the Work zone
- alias: Notify when I leave work
  triggers:
    - trigger: state
      entity_id: person.YOUR_NAME
      from: "Work"
  actions:
    - action: notify.send_message
      target:
        entity_id: notify.YOUR_NOTIFY_SERVICE
      data:
        message: >-
          {% set arrived = trigger.from_state.last_changed %}
          {% set worked_min = ((now() - arrived).total_seconds() / 60) | int %}
          Left at {{ now().strftime('%H:%M') }} - worked
          {{ worked_min // 60 }}h{{ '%02d'|format(worked_min % 60) }}m
```

## 2. Connect the app to Home Assistant

On first launch, click the menu bar icon (shows a gear until configured) and
open Settings. Fill in:

- **Home Assistant URL** — e.g. `https://ha.example.com`
- **Long-lived access token** — from the step above
- **Person entity ID** — your own `person.*` entity, e.g. `person.dave`
  (defaults to `person.nic`)

Click **Test Connection** to confirm before **Save**.

By default your token is stored in the macOS Keychain. Since this app isn't
signed with a Developer ID, its signature changes on every rebuild, which can
make macOS re-prompt for Keychain access after an update. If that bothers
you, turn off **Harden token storage** in Settings — it stores the token in
a plain-text file at `~/.TLNHours.cfg` instead (readable only by you, but
not encrypted). Either way, nothing leaves your Mac.

## Display options

Settings has a **Target Format** section for how the menu bar looks:

- **Icon only** toggle — hides the arrival/leave-time text and shows just the
  briefcase icon. The dropdown itself always shows the full leave time and
  countdown together, regardless of this setting.
- The **Countdown / Leave time** picker only changes the menu bar text itself
  — it doesn't affect the dropdown, which always shows leave time and
  countdown together.

## History

The dropdown has a "History…" button that shows a local log of completed
work sessions. It's stored as plain text at `~/.TLNHours.log` (one line per
day, format `<date>-<time arrived>-<time left>-<worked hours>`, documented
in a comment at the top of the file) and never leaves your Mac.
