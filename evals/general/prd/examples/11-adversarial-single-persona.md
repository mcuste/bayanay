# PRD-001: Dental Clinic Appointment Booking System

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

The dental clinic manages appointments through a manual process (phone calls, paper calendar, or basic spreadsheet). The receptionist spends significant time coordinating schedules, and the lack of a structured system leads to double-bookings, missed appointments, and no easy way to see dentist availability at a glance. When patients call to book or reschedule, the receptionist has to flip through records or scroll through a spreadsheet — slow and error-prone. Missed appointments cost the clinic revenue with no way to proactively remind patients.

## Personas & Use Cases

- **Receptionist** (books and manages all appointments): Primary daily user. Takes patient calls, finds available slots, books appointments, handles cancellations and reschedules. Needs to see dentist availability at a glance and book in under 30 seconds. Currently spends 3–5 minutes per booking due to manual lookup.
- **Dentist** (views their own schedule): Needs to see their day's appointments — patient name, procedure type, and time — at the start of each day and between patients. Not managing bookings, but needs read access to their schedule. Currently asks the receptionist or checks a printout.
- **Clinic Manager** (monitors utilization and no-shows): Needs to understand appointment volume, no-show rates, and schedule utilization to make staffing and operational decisions. Currently has no data — relies on the receptionist's memory and manual tallies.
- **Patient** (books and shows up): While the patient doesn't use the system directly in v1, they're affected by it — they receive appointment confirmations and reminders, and their experience depends on the receptionist having quick access to availability. Modeling the patient helps define reminder behavior and booking constraints.

## Goals & Scope

- **Must have**: Daily and weekly calendar view showing all dentist schedules. Book an appointment — select dentist, date/time slot, patient, procedure type. Cancel and reschedule appointments. Patient record — name, phone number, linked to their appointment history. Conflict detection — prevent double-booking a dentist in the same time slot. Appointment reminders — automated notification to patient (SMS or phone call number displayed for manual call) 24 hours before appointment.
- **Should have**: Search for a patient by name or phone number. View a patient's appointment history. Recurring appointments (e.g., 6-month checkup reminders). No-show tracking — mark appointments where the patient didn't arrive.
- **Non-goals**: Online patient self-booking — v1 is receptionist-only; patient-facing booking portal is a potential future phase. Billing or insurance integration — separate system. Clinical records (treatment notes, X-rays) — this is scheduling, not an EHR. Multi-location support — single clinic for now.

## User Stories

- As the **Receptionist**, I want to see all dentists' availability for a given day so that I can offer the patient open time slots while they're on the phone.
  - **Acceptance**: Calendar view shows all dentists side-by-side with booked and open slots clearly distinguished. Loads in < 2 seconds. Available slots are visually obvious (not requiring mental calculation from booked slots).
  - **Scenario**: Patient calls requesting an appointment with Dr. Smith next Tuesday. Receptionist opens Tuesday's view, sees Dr. Smith's schedule: 9 AM booked, 9:30 booked, 10 AM open, 10:30 open, 11 AM booked. Offers 10 AM or 10:30 AM. Patient picks 10 AM. Receptionist books it in 3 clicks — patient, dentist, and time are pre-filled from context.

- As the **Receptionist**, I want to book an appointment in under 30 seconds so that I don't keep patients waiting on the phone.
  - **Acceptance**: Booking flow requires ≤ 5 interactions (clicks or keystrokes) for a returning patient. For a new patient, includes entering name and phone number — still under 60 seconds. System confirms the booking immediately and shows it on the calendar.
  - **Scenario**: Returning patient calls. Receptionist types first three letters of their name, selects from autocomplete, picks the open slot already visible on the calendar, selects "Cleaning" as procedure type, clicks "Book." Confirmation appears. Total time: 20 seconds.

- As a **Dentist**, I want to see my schedule for today so that I know who's coming in and what procedures to prepare for.
  - **Acceptance**: Dentist can view their own schedule (read-only) filtered to today. Shows patient name, appointment time, and procedure type. Accessible without logging in as a different role (simple view, not the full booking interface).
  - **Scenario**: Dr. Smith arrives at 8:45 AM, opens the schedule screen, sees today's list: 9:00 AM — Jane Doe — Root Canal, 10:00 AM — Bob Lee — Cleaning, 11:00 AM — Sara Kim — Consultation. Knows to prepare the root canal setup first.

- As the **Clinic Manager**, I want to see how many appointments were booked, completed, cancelled, and no-showed this month so that I can track clinic utilization.
  - **Acceptance**: Summary view showing appointment counts by status (booked, completed, cancelled, no-show) for a selectable date range. Shows per-dentist breakdown.
  - **Scenario**: End of month, manager opens the summary. Sees: 320 appointments booked, 290 completed, 15 cancelled, 15 no-shows (4.7% no-show rate). Dr. Smith had 8 no-shows (highest). Manager decides to implement stricter reminder calls for Dr. Smith's patients.

## Behavioral Boundaries

- **Booking conflicts**: System prevents booking two appointments for the same dentist in overlapping time slots. Attempting to book a conflicting slot shows: "Dr. [Name] is already booked at [time]. Next available slot: [time]."
- **Cancellation window**: Appointments can be cancelled or rescheduled up to the appointment time. No restriction on how late — the receptionist manages patient relationships, not the software. Cancelled appointments free the slot immediately.
- **Appointment duration**: Default duration per procedure type (e.g., Cleaning: 30 min, Root Canal: 90 min, Consultation: 15 min). Receptionist can override duration when booking. Calendar displays the actual duration, not a fixed block.
- **Past appointments**: Past appointments are read-only. Cannot be edited or deleted — they're part of the patient's history.

## Non-Functional Requirements

- **Performance**: Calendar view loads in < 2 seconds. Booking confirmation < 1 second. Patient search returns results in < 500ms.
- **Reliability**: Appointment data must never be lost. System should be available during clinic hours (7 AM – 7 PM, Mon–Sat). Acceptable downtime outside clinic hours for maintenance.
- **Security**: Patient data (names, phone numbers) is protected. Access requires login. Receptionist and dentist roles see different views. No patient data exposed without authentication.

## Risks & Open Questions

- **Risk**: Receptionist adoption — if the system is slower than the current manual process, the receptionist will resist it — likelihood: M — mitigation: booking must be faster than manual lookup (< 30 seconds vs. current 3–5 minutes). Involve the receptionist in usability testing before launch.
- **Dependency**: Appointment reminders via SMS require an SMS provider integration. If SMS is not feasible, fall back to displaying "call this patient" prompts in the system for the receptionist to act on manually.
- [ ] How many dentists does the clinic have? (Affects calendar layout — 2 dentists side-by-side is simple; 8 requires a different layout.)
- [ ] What are the clinic's working hours and appointment slot granularity? (15-minute slots? 30-minute?)
- [ ] Does the clinic want patients to receive SMS confirmations at booking time, or only the 24-hour reminder?
- [ ] Should the system support blocking time off (lunch breaks, dentist unavailable)?

## Success Metrics

- Efficiency: Average booking time < 30 seconds (measured from patient search to confirmation), within 2 weeks of adoption
- Accuracy: Zero double-bookings in the first 3 months
- No-show visibility: Clinic tracks no-show rate monthly (baseline established in month 1, target 10% reduction by month 6 via reminders)
- Adoption: Receptionist uses the system for 100% of bookings within 1 week (no parallel paper calendar)
