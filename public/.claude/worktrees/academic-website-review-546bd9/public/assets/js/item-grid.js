/* Filtering, sorting and view switching for the research and software grids.
 *
 * Progressive by design: the server ships every card in the markup and the
 * controls are `hidden` until this file runs, so a reader without JS gets the
 * full list instead of widgets that do nothing.
 *
 * Filtering is AND across facet groups, OR within a group -- picking two
 * topics widens the result, picking a topic and a year narrows it.
 */
(function () {
  "use strict";

  function tokens(el, name) {
    var v = el.getAttribute("data-" + name);
    return v ? v.split("|") : [];
  }

  function setup(section) {
    var controls = section.querySelector(".ig-controls");
    var list     = section.querySelector(".ig-list");
    var status   = section.querySelector(".ig-status");
    var empty    = section.querySelector(".ig-empty");
    if (!list) return;

    var cards   = Array.prototype.slice.call(list.querySelectorAll(".ig-card"));
    var search  = section.querySelector(".ig-search");
    var chips   = Array.prototype.slice.call(section.querySelectorAll(".ig-chip"));
    var clear   = section.querySelector(".ig-clear");
    var sortSel = section.querySelector(".ig-sort-select");
    var views   = Array.prototype.slice.call(section.querySelectorAll(".ig-view button"));

    var showingTpl = section.getAttribute("data-i18n-showing") || "Showing {n} of {m}";
    var active = {};   // facet id -> array of selected slugs

    /* ---------------------------------------------------------- filtering */

    function matches(card) {
      var q = (search && search.value || "").trim().toLowerCase();
      if (q) {
        var blob = card.getAttribute("data-search") || "";
        // every whitespace-separated term must appear somewhere
        var terms = q.split(/\s+/);
        for (var i = 0; i < terms.length; i++) {
          if (blob.indexOf(terms[i]) === -1) return false;
        }
      }
      for (var facet in active) {
        if (!active[facet].length) continue;
        var have = tokens(card, facet);
        var hit = false;
        for (var j = 0; j < active[facet].length; j++) {
          if (have.indexOf(active[facet][j]) !== -1) { hit = true; break; }
        }
        if (!hit) return false;
      }
      return true;
    }

    /* ------------------------------------------------------------ sorting */

    function sortCards(visible) {
      var mode = sortSel ? sortSel.value : "year-desc";
      var by = {
        "year-desc":      function (a, b) { return num(b, "year") - num(a, "year"); },
        // Undated entries sink to the bottom either way, rather than leading
        // the "oldest first" view just because they parse as zero.
        "year-asc":       function (a, b) { return dated(a) - dated(b); },
        "title-asc":      function (a, b) { return str(a).localeCompare(str(b)); },
        "citations-desc": function (a, b) { return num(b, "citations") - num(a, "citations"); }
      }[mode];

      function num(el, name) { return parseInt(el.getAttribute("data-" + name), 10) || 0; }
      function dated(el) { return num(el, "year") || Infinity; }
      function str(el) { return el.getAttribute("data-sort-title") || ""; }

      if (by) visible.sort(by);
      // Reorder the DOM rather than using CSS order, so tab order and screen
      // reader order follow what is on screen.
      visible.forEach(function (card) { list.appendChild(card); });
    }

    /* ------------------------------------------------------------- counts */

    // Recount each chip against everything *except* its own group, so the
    // numbers show what picking that chip would actually give you.
    function recount() {
      chips.forEach(function (chip) {
        var facet = chip.getAttribute("data-facet");
        var value = chip.getAttribute("data-value");
        var saved = active[facet];
        active[facet] = [];
        var n = 0;
        cards.forEach(function (card) {
          if (tokens(card, facet).indexOf(value) !== -1 && matches(card)) n++;
        });
        active[facet] = saved;

        var badge = chip.querySelector(".ig-count");
        if (badge) badge.textContent = n;
        chip.classList.toggle("is-empty", n === 0 && chip.getAttribute("aria-pressed") !== "true");
      });
    }

    /* -------------------------------------------------------------- state */

    function syncUrl() {
      if (!window.history || !window.history.replaceState) return;
      var p = new URLSearchParams();
      if (search && search.value.trim()) p.set("q", search.value.trim());
      Object.keys(active).forEach(function (f) {
        if (active[f].length) p.set(f, active[f].join(","));
      });
      if (sortSel && sortSel.value !== "year-desc") p.set("sort", sortSel.value);
      var qs = p.toString();
      window.history.replaceState(null, "", qs ? "?" + qs : window.location.pathname);
    }

    function readUrl() {
      var p = new URLSearchParams(window.location.search);
      if (search && p.get("q")) search.value = p.get("q");
      if (sortSel && p.get("sort")) sortSel.value = p.get("sort");
      chips.forEach(function (chip) {
        var f = chip.getAttribute("data-facet");
        var wanted = (p.get(f) || "").split(",").filter(Boolean);
        if (wanted.indexOf(chip.getAttribute("data-value")) !== -1) {
          chip.setAttribute("aria-pressed", "true");
          active[f] = (active[f] || []).concat(chip.getAttribute("data-value"));
        }
      });
    }

    /* ------------------------------------------------------------- render */

    function update() {
      var visible = [];
      cards.forEach(function (card) {
        var ok = matches(card);
        card.hidden = !ok;
        if (ok) visible.push(card);
      });

      sortCards(visible);
      recount();

      if (status) {
        status.hidden = false;
        status.textContent = showingTpl
          .replace("{n}", visible.length)
          .replace("{m}", cards.length);
      }
      if (empty) empty.hidden = visible.length !== 0;

      var anyFacet = Object.keys(active).some(function (f) { return active[f].length; });
      if (clear) clear.hidden = !anyFacet && !(search && search.value.trim());

      syncUrl();
    }

    /* --------------------------------------------------------------- wire */

    chips.forEach(function (chip) {
      var facet = chip.getAttribute("data-facet");
      if (!active[facet]) active[facet] = [];
      chip.addEventListener("click", function () {
        var value = chip.getAttribute("data-value");
        var on = chip.getAttribute("aria-pressed") === "true";
        chip.setAttribute("aria-pressed", on ? "false" : "true");
        if (on) {
          active[facet] = active[facet].filter(function (v) { return v !== value; });
        } else {
          active[facet].push(value);
        }
        update();
      });
    });

    if (search)  search.addEventListener("input", update);
    if (sortSel) sortSel.addEventListener("change", update);

    if (clear) {
      clear.addEventListener("click", function () {
        chips.forEach(function (c) { c.setAttribute("aria-pressed", "false"); });
        Object.keys(active).forEach(function (f) { active[f] = []; });
        if (search) search.value = "";
        update();
      });
    }

    views.forEach(function (btn) {
      btn.addEventListener("click", function () {
        views.forEach(function (b) { b.setAttribute("aria-pressed", "false"); });
        btn.setAttribute("aria-pressed", "true");
        list.setAttribute("data-view", btn.getAttribute("data-view"));
      });
    });

    readUrl();
    if (controls) controls.hidden = false;
    update();
  }

  function init() {
    Array.prototype.slice
      .call(document.querySelectorAll(".item-grid"))
      .forEach(setup);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
