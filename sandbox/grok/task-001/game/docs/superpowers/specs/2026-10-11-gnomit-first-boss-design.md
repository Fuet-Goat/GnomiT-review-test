# GnomiT first Boss playable skeleton
User authorized implementation now, with corrections after a playable version (2026-10-11). This record follows the prior discussed direction; it does not start another approval round.
Separate new Godot project in the original private GnomiT workspace (not included in this test repository). Never modify Cradle source, builds or its campaign save.
Six levels: entry (simple collection), hollow (holes/gravity), seam (partial golden floor), rune (sealed runes), lantern (blue crystal collection), guardian (runes + blue crystals). Three ordinary nodes then separate Boss chamber with free-order RUNE/LANTERN and locked final until both won.
Moves, no timer. Win 1 star, 2 at >=25% initial moves remaining, 3 at >=50%. These are editable first-skeleton balance values. No progression barrier above 1 star.
Local persistent save with version, best stars, one-time first reward and separate preparations. Level progress saved at terminal victory. Exit/loss keeps previous wins. New-game reset requires explicit UI confirmation.
Visuals: quiet magical underground map, six distinct gem silhouettes, warm wood/gold frames, gnome companion, descending transitions, 4 chamber states, goal icons, correct 1-3 stars. Background painting is reference/decoration; numbers/buttons/counters are live UI.
Animations: valid/invalid swaps, clear burst, downward gravity with one bounce, objective sparkle, lantern charge, rune unlock, guardian eyes/light reaction, star reveal, downward map transition; reduce-motion option keeps same state and brief static feedback.
Mouse click/drag plus touch-compatible controls; portrait base 720x1100, expandable desktop window, fullscreen option. Internal test Windows native EXE with embedded pack. Escape pauses; pause/retry/map/options; quit saves progress.
No account/shop/lives/building economy needed. Ordinary goals and Boss preparation unlocks visible; hints identify a legal swap without spending moves.
Core must avoid initial matches, preserve holes, refill independent vertical segments, handle invalid swaps without spending moves, bounded cascades and no-move recovery.
