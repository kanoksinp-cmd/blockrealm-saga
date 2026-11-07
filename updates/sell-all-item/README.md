# Sell every copy of one item

Adds a Sell All button to each item card in the NPC shop Sell tab, on desktop and mobile. It reads the current bag stack on activation and uses the existing pricing and transaction flow. Other inventory items and equipped gear are retained. The button is absent from Buy, and stale sell callbacks cannot become purchase actions. Quantity-based selling remains available. Mobile uses the existing 54-pixel minimum button height and window scrolling.

Validated by activating the actual item-card button: a 20,007-item stack (including inventory changes after opening), exact Zeny proceeds, other stacks and equipment retained, repeat activation safe, ordinary quantity sales retained, no Sell All on Buy, stale callback safe, and mobile window bounds/touch size. Isolated test saves on PC 1280x720 and mobile 1055x488.
