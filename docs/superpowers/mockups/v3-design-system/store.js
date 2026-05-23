/* ============================================================================
   PokerSpot mockup — tiny localStorage store (demo persistence only)
   Flutter: this is replaced by repositories (Firestore). Keys are prefixed
   "ps_" so "Reset demo data" can clear them without touching anything else.
   ========================================================================== */
const PSStore = {
  get(key, fallback) {
    try { const v = JSON.parse(localStorage.getItem('ps_' + key)); return v == null ? fallback : v; }
    catch (e) { return fallback; }
  },
  set(key, val) { localStorage.setItem('ps_' + key, JSON.stringify(val)); },
  push(key, item) { const a = PSStore.get(key, []); a.push(item); PSStore.set(key, a); return a; },
  reset() {
    Object.keys(localStorage).filter(k => k.indexOf('ps_') === 0).forEach(k => localStorage.removeItem(k));
  }
};
