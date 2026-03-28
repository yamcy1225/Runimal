# Runimal Game Concept And Reward System

## 1. Product Summary

Runimal is a running companion game for iPhone and Apple Watch.

The core fantasy is simple:

- Real running data becomes game energy
- Energy turns into eggs, companions, growth, and evolution
- The player raises one main companion or one main egg at a time
- Repeated running creates a long-term collection, build strategy, and seasonal progression loop

This is not a basic running log viewer.
It is a creature-raising RPG driven by real-world runs.

## 2. Core Player Fantasy

The player should feel:

- “My run created something alive.”
- “My running style changes what may hatch.”
- “I choose whether this run becomes a new egg or growth for my current companion.”
- “I am building a stable, not just collecting workout history.”

The emotional arc is designed around:

1. Run on Apple Watch
2. Finish the run
3. Receive a Run Core reward
4. Choose what to do with that reward
5. Hatch, feed, grow, evolve
6. Return to the next run with a clearer goal

## 3. Core Game Loop

### 3.1 Run Loop

1. The player starts a run on Apple Watch.
2. Live run metrics are tracked.
3. When the run ends, the game creates a completed run record and a Run Core reward.
4. The reward syncs to iPhone.
5. The player uses the reward in one of two ways:
   - turn it into a new egg
   - feed it to the current main companion

### 3.2 Companion Loop

1. The player owns companions and eggs.
2. Only one target is carried as the main slot at a time.
3. If the main slot is a companion:
   - runs can feed it directly
4. If the main slot is an egg:
   - runs incubate the egg
5. When incubation reaches the threshold:
   - the egg hatches into a new companion

### 3.3 Long-Term Loop

1. Complete runs
2. Unlock achievements
3. Earn eggs under specific conditions
4. Expand the companion roster
5. Build specialized companions
6. Claim weekly and seasonal rewards
7. Prepare for advanced content such as raids and challenges

## 4. Main Slot System

The player can carry only one main target at a time.

### 4.1 Main Companion

When a companion is selected as main:

- Run Cores can be fed to that companion
- Growth and evolution progress focus on that companion
- Weekly effects and build bonuses apply to that companion

### 4.2 Main Egg

When an egg is selected as main:

- New runs can incubate that egg
- The egg becomes the current progression target
- The player sees only shell type, progress, and hints
- The final hatch result remains hidden until hatch time

This structure forces a meaningful choice:

- grow current power
- or invest in future collection

## 5. Egg System

## 5.1 Egg Philosophy

Eggs are intentionally mysterious.

The player should not know the exact hatch result from the beginning.
Eggs are presented as hidden entities rather than preview cards for a fixed pet.

### 5.2 Egg Presentation

Each egg:

- starts with the name `???`
- shows a shell type
- shows incubation progress
- shows a hint about what behaviors increase certain hatch outcomes

The player does not see the exact species in advance.

## 5.3 Egg Acquisition Rules

Eggs are not earned from every run.

An egg can be created only when at least one of these conditions is true:

1. A new achievement was unlocked by that run
2. All companion slots and egg slots were empty, and the player completed the first successful run after that reset state

This makes eggs feel rare and intentional.

## 5.4 Egg Shell Types

Current shell types:

- Ember
- Gale
- Moss
- Dusk
- Stone

Shell type is inferred from the run style.
Examples:

- fast pace or high cadence tends toward Ember
- long distance tends toward Gale
- night running tends toward Dusk
- climbing tends toward Stone
- balanced natural runs tend toward Moss

## 5.5 Hatch Probability Logic

Egg results are mostly random, but not fully random.

The final hatch result is influenced by:

- shell type
- source run metrics
- additional incubation runs
- player reward history in some cases

This means:

- the player cannot guarantee a specific pet
- but can improve the chance of certain species through behavior

Example design intent:

- stable long runs increase wind or endurance-style outcomes
- high-cadence aggressive runs increase fast or flame-style outcomes
- climbing increases heavy or earth-style outcomes
- night runs increase hidden or lunar-style outcomes

## 5.6 Egg Consumption Rules

Runs used to create or incubate an egg are consumed by that egg.

When the egg hatches:

- those runs transfer into the new companion’s ownership history
- they cannot be reused as free growth material

## 6. Companion System

## 6.1 Species

Current species set includes:

- Windrunner
- Stoneback
- Sparkfang
- Mosshop
- Shadebit
- Seedle

Each species has its own silhouette, identity, and affinity pattern.

## 6.2 Rare Variants

Rare variants are higher-value versions with stronger flavor and visuals.

Current rare variant set includes:

- Tempo Surge
- Zen Bloom
- Summit Heart
- Eclipse Mark
- Loop Sigil

Rare variants are tied to run patterns and special conditions.

## 6.3 Evolution

Companions grow through repeated feeding and progression.

Evolution is based on:

- total accumulated experience
- feed count
- run style influence
- variant and progression context
- seasonal factors in advanced systems

The goal is for evolution to feel earned, not automatic.

## 7. Run Rewards

Each finished run creates a Run Core package.

A Run Core includes:

- core label
- experience value
- generated reward pet flavor
- quest completion context
- flavor text

The reward is not just a number.
It is a game object that enters the player’s progression decision flow.

## 7.1 Run Core Decisions

For each eligible Run Core, the player may:

1. Create Egg
2. Feed Main Companion
3. Incubate Main Egg

However, egg creation is only enabled when egg conditions are met.

## 7.2 Reward Ownership

Runs are assigned to one of these outcomes:

- companion growth
- egg creation
- egg incubation

This prevents the same run from being endlessly reused.

## 8. Achievement System

Achievements are part of the reward gate for eggs.

Their current design purpose is:

- give milestone meaning to certain runs
- make eggs feel like real unlocks
- connect player behavior to collectible rewards

Examples of achievement-style triggers:

- reaching distance thresholds
- high cadence
- strong climb
- night run completion

New achievement unlocks are tracked and used to determine whether a run can create a new egg.

## 9. Weekly Reward System

Weekly progression adds a layer above individual runs.

The player completes weekly missions and claims weekly rewards.

### 9.1 Weekly Reward Effects

Weekly rewards can grant effects such as:

- extra XP
- better rare windows
- evolution acceleration

These effects influence:

- growth math
- reward feeling
- live watch coaching in some systems

### 9.2 Weekly Board Purpose

The weekly board exists to answer:

- why should I run again this week?
- what is my current progression target?
- what bonus am I playing under right now?

## 10. Seasonal System

Seasonal progression adds identity and longer-term rotation.

Seasonal content may affect:

- reward themes
- bonus context
- unlock tracks
- cosmetic layers
- advanced evolution names
- endgame encounter themes

The goal is to keep the collection meta fresh over time.

## 11. Resource Economy

The game includes multiple resources beyond basic XP.

### 11.1 Essence

Essence is used for:

- build upgrades
- forging advanced bonuses
- long-term collection economy

### 11.2 Overdrive Charges

Overdrive is a burst-style growth bonus used in higher-level progression systems.

### 11.3 Season Sigils

Season Sigils connect weekly or seasonal progression to stronger bonuses and themed unlocks.

### 11.4 Raid Shards

Raid Shards are endgame-oriented resources linked to raid success and higher-level rewards.

## 12. Build And Role System

Companions are not only cosmetic.
They can be specialized.

Current role concept includes paths such as:

- Vanguard
- Relay
- Oracle

The role/build system is meant to create real roster decisions:

- which companion is best for this week
- which companion synergizes with current effects
- which companion should receive scarce resources

## 13. Collection And Roster Philosophy

The game is not about owning one perfect creature only.
It is about managing a stable of different companions.

The roster system should support:

- choosing one main slot
- keeping multiple backups
- raising eggs for future options
- comparing resonance and synergy
- retiring duplicates into economy resources

## 14. Apple Watch Role

Apple Watch is not a menu-heavy management screen.
It is the live play device.

Its role is:

- start and finish runs
- show live coaching
- display current target state
- reflect momentum and rare windows
- act as the field side of the game

The watch should emphasize:

- current state
- current action
- immediate reward anticipation

## 15. iPhone Role

iPhone is the home base.

Its role is:

- review rewards
- choose how to spend Run Cores
- manage the main slot
- incubate eggs
- hatch companions
- track collection and growth
- handle weekly, seasonal, and advanced progression

## 16. Design Principles

The current product should follow these principles:

### 16.1 Mystery Before Certainty

Eggs should preserve mystery.
The player should feel probability, not certainty.

### 16.2 Running Style Matters

Different running behaviors should gradually bias outcomes.
The player should feel that habits matter.

### 16.3 One Main Focus

Only one main slot should matter at a time.
This creates strategic clarity.

### 16.4 Every Run Must Ask A Question

After each run, the player should think:

- new egg?
- current growth?
- future collection investment?

### 16.5 Visual Readability Over Text Density

The game should communicate through:

- shell visuals
- sprite silhouettes
- badges
- bars
- stage accents

Not dense paragraphs.

## 17. Current Product Promise

Runimal currently aims to deliver this promise:

“Your runs do not just get recorded. They become living companions, hidden eggs, rare hatches, and long-term growth choices.”

## 18. Future Expansion Directions

Natural next expansions include:

- more shell families
- more species and rare variants
- stronger achievement ladders
- more seasonal hatch bias rules
- richer raid and challenge rewards
- advanced hatch cinematics
- deeper build specialization
- live watch goals that explicitly guide hatch probability windows

