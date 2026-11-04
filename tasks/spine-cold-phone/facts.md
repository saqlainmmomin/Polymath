# Fact sheet: Why does your phone die at 30% when it's freezing?

## 1. Is the title literally true?
Not quite. "Die at 30%" is one example, not a rule: the percentage at which a cold phone shuts off varies with the phone, its battery age and how cold it is, and no source gives a standard figure. "Freezing" (0 degrees C) is also only the edge of Apple's designed range (0 to 35 C), so shutdowns are much commoner well below it. "Die" also hides the twist: the phone is not dead and the charge is not gone.
Closest literally true plain-words question: **"Why does your phone shut off with battery left when it's freezing outside?"** (Alternative: "Why can a cold phone switch off with charge still in it?") The copy may use 30% as an example number ("it said 30%") but must not claim 30% is typical.

## 2. The answer in one sentence
In the cold the battery's insides move sluggishly, so it cannot push out current easily and its voltage sags; the phone's percentage (a guess partly based on voltage) drops fast, and the phone switches off when the voltage falls too low, but the charge is still there and comes back when the battery warms.

## 3. Safe claims
1. Apple designs iPhones for use where the air temperature is between 0 and 35 degrees Celsius (32 to 95 F).
   *high — https://support.apple.com/en-us/118431*
2. Apple says using an iPhone in cold outside that range shortens its battery life for a while and can make it turn off.
   *high — https://support.apple.com/en-us/118431 ("might temporarily shorten battery life", "could cause your device to turn off")*
3. A phone battery carries its charge as lithium ions moving through a liquid between two layers called electrodes.
   *high — https://en.wikipedia.org/wiki/Lithium-ion_battery*
4. In the cold the liquid inside a lithium-ion battery gets thicker, and the ions move through it more slowly.
   *high — https://pubs.rsc.org/en/content/articlehtml/2025/ra/d4ra08490j (RSC Advances review, Liu, Sheng, Jiang 2025: rising viscosity slows ion movement). Page blocked direct fetch; read via search summary. Also https://pubs.rsc.org/en/content/articlehtml/2025/eb/d5eb00013k*
5. A cold battery has more internal resistance, so it cannot push out as much current at once.
   *high — https://batteryuniversity.com/article/bu-502-discharging-at-high-and-low-temperatures ("Cold temperature increases the internal resistance and lowers the capacity")*
6. While a battery is delivering current, the voltage at its terminals sags below its resting voltage, and the sag is bigger when its internal resistance is higher.
   *medium-high — basic circuit physics (voltage drop = current x resistance); US patent 9,585,100 states it for phones (PDF is image-only, read via search summary): https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9585100*
7. A phone cannot measure the charge left directly; it estimates the percentage, partly from the battery's voltage.
   *high — https://batteryuniversity.com/article/bu-903-how-to-measure-state-of-charge ; TI fuel-gauge datasheet (uses current, open-circuit voltage, voltage under load): https://www.ti.com/document-viewer/BQ27427/datasheet/GUID-CA1A1DB0-793B-472C-B37D-1B0D3E3867BF*
8. Cold lowers the voltage a battery shows, so a cold battery can look emptier than it is.
   *medium-high — https://batteryuniversity.com/article/bu-903-how-to-measure-state-of-charge ("heat raises the voltage while cold causes a decrease"; voltage-based charge readings are inaccurate because temperature affects the voltage)*
9. If the battery's voltage under load falls below the minimum the phone needs to run, the phone switches off.
   *medium — US patent 9,585,100 ("if terminal voltage drops below the minimum operating voltage, the device may lose power"): https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9585100*
10. The capacity a battery loses in the cold is only lost while it is cold, and it comes back at room temperature.
    *high — https://batteryuniversity.com/article/bu-502-discharging-at-high-and-low-temperatures ; Apple: "Battery life will return to normal when you bring your device back to higher ambient temperatures", https://support.apple.com/en-us/118431*
11. Charging a lithium-ion battery below 0 degrees Celsius makes metallic lithium plate onto the electrode, which permanently damages it.
    *high — https://batteryuniversity.com/article/bu-410-charging-at-high-and-low-temperatures ("leads to a permanent degradation in performance and safety"); https://en.wikipedia.org/wiki/Lithium-ion_battery*
12. Apple says a very hot phone can have its battery life shortened for good, but the shortening from cold is temporary.
    *high — https://support.apple.com/en-us/118431 and https://www.apple.com/batteries/maximizing-performance/ ("this condition is temporary")*

Notes for the writer:
- Claims 8 and 9 are the "why the % is wrong" step. Do not say the phone "reads only voltage": real gauges also use current and temperature, and still get it wrong in the cold. Say "partly from voltage" or "a guess".
- "To protect itself" is NOT in a source as stated. Safe version: the phone switches off when the voltage gets too low to run on. Do not say it saves the battery from damage.
- Claim 11 is about charging, not using. Claim 12 is the reassurance. Apple also says a phone can pause charging when too cold or hot (https://www.apple.com/batteries/maximizing-performance/), so phones often protect themselves there.

## 4. Myths to avoid
- **"The cold drains the charge away."** False. The charge stays; it is harder to get out until the battery warms.
- **"The battery freezes solid."** False for these batteries. The battery is slow, not frozen; specialty Li-ion runs to -40 C at reduced rate (https://batteryuniversity.com/article/bu-502-discharging-at-high-and-low-temperatures).
- **"The phone dies at exactly 0 C."** False. 0 C is the edge of Apple's designed range, not a switch.
- **"The percentage is a precise reading, so the phone is broken."** False. It is an estimate; the cold makes it wrong, not the phone faulty.
- **"Cold permanently ruins your battery."** False for using it in the cold; the harm comes from charging while below freezing.
- **"Warm it fast on a heater or hair dryer."** Not sourced; do not recommend. Say "let it warm up".
- **"30% is when phones die."** Invented; no source gives a typical figure.

## 5. One good number
A typical battery that gives 100 percent of its capacity at 27 C gives only about 50 percent at -18 C, which is a home freezer's usual temperature.
*Source: https://batteryuniversity.com/article/bu-502-discharging-at-high-and-low-temperatures ("100 percent capacity at 27 C ... 50 percent at -18 C"). Caveat: a general figure for batteries, not a measurement of any phone, and it depends on how hard the battery is worked. Say "a typical battery", never "your phone".*

Rejected: a shutdown percentage or shutdown temperature for phones; no manufacturer or study publishes one.

## 6. Everyday comparisons
- **Honey through a straw.** Cold makes the liquid thicker so the ions drag; you can still drink, just slowly, and warm honey flows again. Right intuition for slower ions and for "recovers when warm". Misleads if the reader thinks the battery is a thick sludge or a tank running dry; the honey is all still there, which is the point. Usable.
- **A fuel gauge that guesses from tap pressure.** Imagine guessing how full a water tank is by how hard the water pushes out when someone runs a hose. Pressure sags while the hose is open, so the tank looks emptier than it is. Right intuition for voltage sag and the wrong %. Misleads if the reader concludes the gauge is dumb or broken, or that phones read voltage alone (see notes). Say "a guess", not "a faulty gauge".
- **A crowded exit through a narrow door.** Cold narrows the door: people (ions) are all inside, but few get through at once. Right for "cannot push out current". Misleads if read as ions being lost or trapped for good; they are not. Weakest of the three.
