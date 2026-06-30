/*
 * Cloud-Native Support sidebar enhancements for the curated component sites
 * (which do not ship the shared tt-search.js). Two behaviours:
 *
 *  1. initSidebarCarets() -- expand/collapse. Standalone extract of the same
 *     function in the shared theme's tt-search.js; keep in sync if it changes.
 *     collapse_navigation is False, so every parent's subtree is in the DOM and
 *     CSS folds it (.tt-open expands). Seed the active path open, then toggle
 *     .tt-open when the caret zone (right edge of a parent row) is clicked.
 *
 *  2. internalizeSameOriginLinks() -- the shared external-nav-links.js forces
 *     target="_blank" + an "open in new tab" icon on every .reference.external
 *     sidebar link, including cross-links to sibling docs.tenstorrent.com
 *     sub-sites (which are SAME-ORIGIN in production, and rewritten to local
 *     paths in the preview). For those, drop target/rel so they open in the
 *     same tab, and tag them so the icon is suppressed (see the .tt-same-origin
 *     rule in the layout). Genuinely off-site links keep the new-tab behaviour.
 *     Runs after external-nav-links.js (loaded earlier in the footer).
 */
(function () {
  "use strict";

  function hasChildUl(li) {
    for (var i = 0; i < li.children.length; i++) {
      if (li.children[i].tagName === 'UL') return true;
    }
    return false;
  }

  function initSidebarCarets() {
    var menu = document.querySelector('.wy-menu-vertical');
    if (!menu) return;

    // Seed: expand the active path (RTD marks the current page + its ancestors).
    menu.querySelectorAll('li.current').forEach(function (li) {
      if (hasChildUl(li)) li.classList.add('tt-open');
    });

    // The caret is the ::after on the parent <a>; treat the right 34px as its
    // hit zone so the rest of the label still navigates.
    menu.querySelectorAll('li > a').forEach(function (a) {
      var li = a.parentElement;
      if (!hasChildUl(li)) return;
      a.addEventListener('click', function (e) {
        var rect = a.getBoundingClientRect();
        if (e.clientX >= rect.right - 34) {
          e.preventDefault();
          e.stopPropagation();
          li.classList.toggle('tt-open');
        }
      });
    });
  }

  function internalizeSameOriginLinks() {
    var menu = document.querySelector('.wy-menu-vertical');
    if (!menu) return;
    menu.querySelectorAll('a.reference.external').forEach(function (a) {
      if (a.hostname === window.location.hostname) {
        a.removeAttribute('target');
        a.removeAttribute('rel');
        a.classList.add('tt-same-origin');
      }
    });
  }

  function init() {
    initSidebarCarets();
    internalizeSameOriginLinks();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
