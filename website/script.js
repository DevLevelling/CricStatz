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

    // Background call to increment downloads in the database
    try {
      if (window.supabase) {
        // Reuse the already created supabase client if possible, or recreate with known globals if they were in scope.
        // Wait, supabaseUrl and supabaseKey are defined further down in the file! We can't use them here unless we move them up.
        // Let's just use the cachedData to optimistically update, and let the NEXT fetch loop grab the real data.
        
        // Let's create the client with hardcoded credentials just for this click to ensure it works, 
        // OR better yet, let's move the credentials up. Actually, we'll just inline the keys here to be totally safe and fix the bug without large refactors.
        const url = 'https://phxazbsbnglpjnauhxah.supabase.co';
        const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoeGF6YnNibmdscGpuYXVoeGFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNjYwNDQsImV4cCI6MjA4Nzk0MjA0NH0.7mrMb6OnPIiShYZqOexiRcWbeLghAKtdncVhbIVRyA8';
        const client = window.supabase.createClient(url, key);
        
        client.rpc('increment_downloads').then(({error}) => {
          if (error) console.error("Increment error:", error);
        });
        
        // Optimistically update the UI counter immediately
        const metricDownloads = document.getElementById('metricDownloads');
        let newTotalDownloads = 0;
        if (metricDownloads && metricDownloads.innerText !== "...") {
           let currentVal = parseInt(metricDownloads.getAttribute('data-target') || '0', 10);
           currentVal += 1;
           newTotalDownloads = currentVal;
           metricDownloads.setAttribute('data-target', currentVal);
           metricDownloads.innerText = currentVal.toLocaleString();
        }
        
        // Optimistically update the social proof text as well
        if (newTotalDownloads > 0) {
           const socialDescText = document.getElementById('socialDescText');
           if (socialDescText) {
              socialDescText.innerText = `Thousands of secure matches. Over ${newTotalDownloads.toLocaleString()} downloads and growing.`;
           }
        }
      }
    } catch (e) {
      console.error("Failed to increment counter:", e);
    }

    // Reset: remove all state classes
    overlay.classList.remove("active", "swung", "impact");

    // Force a reflow so the browser registers the removal
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

  // ── 5. Trust Metrics Counter Animation ──────────────────
  const metricValues = document.querySelectorAll('.metric-value');
  let hasAnimatedMetrics = false;

  const animateCounters = () => {
    metricValues.forEach(valueEl => {
      // Get the target number from data attribute, ignore if it's "..."
      const targetStr = valueEl.getAttribute('data-target');
      if (!targetStr || targetStr === "...") return;

      const target = parseInt(targetStr, 10);
      if (isNaN(target)) return;

      const duration = 2000; // ms
      const startTime = performance.now();

      const updateCounter = (currentTime) => {
        const elapsedTime = currentTime - startTime;
        const progress = Math.min(elapsedTime / duration, 1);
        
        // Easing function: easeOutExpo
        const easeProgress = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
        
        const currentVal = Math.floor(easeProgress * target);
        valueEl.innerText = currentVal.toLocaleString();

        if (progress < 1) {
          requestAnimationFrame(updateCounter);
        } else {
          valueEl.innerText = target.toLocaleString();
        }
      };
      
      requestAnimationFrame(updateCounter);
    });
  };

  const metricsObserver = new IntersectionObserver((entries) => {
    if (entries[0].isIntersecting && !hasAnimatedMetrics) {
      hasAnimatedMetrics = true;
      animateCounters();
    }
  }, { threshold: 0.2 });

  const trustSection = document.getElementById('trust');
  if (trustSection) {
    metricsObserver.observe(trustSection);
  }

  // ── 6. Supabase Live Data Fetching ──────────────────────
  const supabaseUrl = 'https://phxazbsbnglpjnauhxah.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoeGF6YnNibmdscGpuYXVoeGFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNjYwNDQsImV4cCI6MjA4Nzk0MjA0NH0.7mrMb6OnPIiShYZqOexiRcWbeLghAKtdncVhbIVRyA8';
  
  let lastFetched = 0;
  let cachedData = null;

  const fetchSupabaseStats = async () => {
    const liveIndicatorText = document.getElementById('liveIndicatorText');
    
    // Check cache (1 minute TTL)
    const now = Date.now();
    if (cachedData && (now - lastFetched) < 60000) {
      return;
    }

    try {
      if (!window.supabase) {
        throw new Error("Supabase JS client not loaded. Blocked by browser?");
      }

      const client = window.supabase.createClient(supabaseUrl, supabaseKey);
      
      // Call the secure RPC function
      const { data, error } = await client.rpc('get_app_metrics');

      if (error) {
         throw new Error(`DB Error: ${error.message}`);
      }
      
      // If RPC is not created yet, data might be null
      if (!data) {
         throw new Error('RPC function get_app_metrics not found. Please run the SQL migration.');
      }

      // ── Fetch Real User Avatars ──
      // Fetch 4 recently created users
      const { data: avatarData, error: avatarError } = await client
        .from('profiles')
        .select('avatar_url, display_name')
        .order('created_at', { ascending: false })
        .limit(4);

      if (!avatarError && avatarData) {
         const avatarGroup = document.getElementById('socialAvatars');
         if (avatarGroup) {
            // Build real avatar HTML
            let avatarsHTML = '';
            avatarData.forEach(user => {
               // Use a simple blank placeholder if they haven't uploaded an avatar
               const avatarSrc = user.avatar_url || 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';
               avatarsHTML += `<img src="${avatarSrc}" alt="${user.display_name || 'User'}" class="avatar" style="object-fit: cover; background: #fff;">`;
            });
            // If less than 4 users, that's totally fine, it will just show whatever exists
            avatarsHTML += `<div class="avatar more">+</div>`;
            avatarGroup.innerHTML = avatarsHTML;
         }
      }

      const totalUsers = data.registered_users || 0;
      const loginsToday = data.daily_logins || 0;
      const activeUsers = data.active_users || 0;
      const totalDownloads = data.total_downloads || 0;

      // Update Social Proof Texts
      const socialUsersText = document.getElementById('socialUsersText');
      const socialDescText = document.getElementById('socialDescText');
      
      if (socialUsersText) socialUsersText.innerText = `Trusted by ${totalUsers.toLocaleString()}+ users.`;
      if (socialDescText) socialDescText.innerText = `Thousands of secure matches. Over ${totalDownloads.toLocaleString()} downloads and growing.`;

      // Update UI elements with exact real data
      const targetDownloads = document.getElementById('metricDownloads');

      const targetUsers = document.getElementById('metricUsers');
      const targetDAU = document.getElementById('metricDAU');
      const targetLogins = document.getElementById('metricLogins');

      if (targetDownloads) targetDownloads.setAttribute('data-target', totalDownloads);
      if (targetUsers) targetUsers.setAttribute('data-target', totalUsers);
      if (targetDAU) targetDAU.setAttribute('data-target', activeUsers);
      if (targetLogins) targetLogins.setAttribute('data-target', loginsToday);
      
      if (liveIndicatorText) {
        liveIndicatorText.innerText = `🔥 Real-time Database Connected. Live Tracking Active.`;
      }
      
      // Init real textual data if hasn't been animated yet
      if (!hasAnimatedMetrics) {
        if (targetDownloads) targetDownloads.innerText = "0";
        if (targetUsers) targetUsers.innerText = "0";
        if (targetDAU) targetDAU.innerText = "0";
        if (targetLogins) targetLogins.innerText = "0";
      }
      
      cachedData = { totalUsers, loginsToday, activeUsers, totalDownloads };
      lastFetched = now;

      // Re-trigger animation
      if (hasAnimatedMetrics) animateCounters();

    } catch (error) {
      console.error("Live stats error:", error);
      if (liveIndicatorText) {
        liveIndicatorText.innerHTML = `<span style="color:#f87171;">⚠️ ${error.message}</span>`;
      }
    }
  };

  fetchSupabaseStats();
  setInterval(fetchSupabaseStats, 60000);
});
