/* =========================================================
   CricStatz – Main Script
   Handles: Scroll reveals, nav active state, download animation
   ========================================================= */

document.addEventListener("DOMContentLoaded", () => {

  // ── 1. Scroll-Reveal with IntersectionObserver ──────────
  const revealElements = document.querySelectorAll(
    ".reveal, .reveal-left, .reveal-right, .reveal-scale"
  );

  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
        }
      });
    },
    { threshold: 0.15, rootMargin: "0px 0px -40px 0px" }
  );

  revealElements.forEach((el) => revealObserver.observe(el));

  // ── 2. Active Nav Link on Scroll ────────────────────────
  const sections = document.querySelectorAll(".section[id]");
  const navLinks = document.querySelectorAll(".nav-links a");

  const navObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const id = entry.target.getAttribute("id");
          navLinks.forEach((link) => {
            link.classList.toggle(
              "active",
              link.getAttribute("href") === `#${id}`
            );
          });
        }
      });
    },
    { threshold: 0.4 }
  );

  sections.forEach((section) => navObserver.observe(section));

  // ── 3. Cricket Download Animation (Multi-phase) ─────────
  const downloadBtn = document.getElementById("downloadBtn");
  const overlay = document.getElementById("cricketOverlay");
  const hiddenLink = document.getElementById("hiddenDownload");
  const batsman = document.getElementById("cricketBatsman");
  const ball = document.getElementById("cricketBall");

  let animating = false;

  // Helper: force animation restart on an element by cloning it
  function restartAnimation(el) {
    const clone = el.cloneNode(true);
    el.parentNode.replaceChild(clone, el);
    return clone;
  }

  downloadBtn.addEventListener("click", () => {
    if (animating) return;
    animating = true;

    // Reset: remove all state classes
    overlay.classList.remove("active", "swung", "impact");

    // Force a reflow so the browser registers the removal
    void overlay.offsetWidth;

    // Phase 1: Dark backdrop + batsman enters from left (0 → 0.5s)
    overlay.classList.add("active");

    // Phase 2: Bat swing (at 0.55s the bat connects)
    setTimeout(() => {
      overlay.classList.add("swung");
    }, 550);

    // Phase 3: Ball launches from bat toward user (CSS: 0.6s delay on .active)
    // Ball scales up and flies at the screen over 0.7s

    // Phase 4: Ball "hits" the screen — white flash + screen crack (at 1.3s)
    setTimeout(() => {
      overlay.classList.add("impact");
    }, 1300);

    // Phase 5: Hold the cracked screen, then clean up + trigger download
    setTimeout(() => {
      overlay.classList.remove("active", "swung", "impact");
      animating = false;

      // Trigger actual download
      hiddenLink.click();
    }, 3200);
  });

  // ── 4. Navbar background on scroll ──────────────────────
  const navbar = document.getElementById("navbar");
  window.addEventListener("scroll", () => {
    if (window.scrollY > 80) {
      navbar.style.background = "rgba(0, 0, 0, 0.85)";
    } else {
      navbar.style.background = "rgba(0, 0, 0, 0.6)";
    }
  });
});
