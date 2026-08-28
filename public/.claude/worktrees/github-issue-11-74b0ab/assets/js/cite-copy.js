/* Copy-to-clipboard for the BibTeX block on detail pages. */
(function () {
  "use strict";

  function init() {
    var buttons = document.querySelectorAll(".cite-copy");
    Array.prototype.forEach.call(buttons, function (btn) {
      var label = btn.textContent;
      btn.addEventListener("click", function () {
        var pre = document.getElementById(btn.getAttribute("data-target"));
        if (!pre) return;
        var text = pre.textContent;

        function done() {
          btn.textContent = btn.getAttribute("data-copied") || "Copied";
          btn.classList.add("is-copied");
          setTimeout(function () {
            btn.textContent = label;
            btn.classList.remove("is-copied");
          }, 1600);
        }

        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(done, fallback);
        } else {
          fallback();
        }

        // Older Safari and any non-secure context land here.
        function fallback() {
          var ta = document.createElement("textarea");
          ta.value = text;
          ta.setAttribute("readonly", "");
          ta.style.position = "absolute";
          ta.style.left = "-9999px";
          document.body.appendChild(ta);
          ta.select();
          try { document.execCommand("copy"); done(); } catch (e) { /* give up quietly */ }
          document.body.removeChild(ta);
        }
      });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
