(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  let current = 'login', sampleIdx = 0, scanTimer = null, detecting = false;

  /* ---------- navigation ---------- */
  function go(name) {
    if (name === current) return;
    const from = $(`[data-screen="${current}"]`), to = $(`[data-screen="${name}"]`);
    from.classList.add('leaving'); from.classList.remove('active');
    setTimeout(() => from.classList.remove('leaving'), 460);
    to.classList.add('active'); current = name;
    clearTimeout(scanTimer);
    if (name === 'scan') startScan();
    if (name === 'result') renderResult();
    const sc = $('.scroll', to); if (sc) sc.scrollTop = 0;
  }
  let tt;
  function toast(m) { const t = $('#toast'); t.textContent = m; t.classList.add('show'); clearTimeout(tt); tt = setTimeout(() => t.classList.remove('show'), 2200); }

  /* ---------- P1 login ---------- */
  const email = $('#email'), pass = $('#pass'), btn = $('#loginBtn');
  $('#eye').onclick = e => {
    const show = pass.type === 'password'; pass.type = show ? 'text' : 'password';
    e.currentTarget.classList.toggle('on', show);
    e.currentTarget.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
  };
  [email, pass].forEach(i => i.addEventListener('input', () => { i.classList.remove('bad'); $('#' + i.id + 'Err').textContent = ''; }));
  $('#loginForm').addEventListener('submit', e => {
    e.preventDefault();
    let ok = true;
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim())) { $('#emailErr').textContent = 'Enter your clinic email, like you@clinic.com.'; email.classList.add('bad'); ok = false; }
    if (pass.value.length < 6) { $('#passErr').textContent = 'Enter your password (at least 6 characters).'; pass.classList.add('bad'); ok = false; }
    if (!ok) return;
    btn.classList.add('loading'); btn.disabled = true; $('span', btn).textContent = 'Logging in';
    setTimeout(() => {
      btn.classList.remove('loading'); btn.disabled = false; $('span', btn).textContent = 'Log in';
      toast('Welcome back'); go('scan');
    }, 1100);
  });

  /* ---------- P2 scan ---------- */
  const frame = $('#frame'), status = $('#status');
  function startScan() {
    detecting = false; frame.classList.remove('found'); status.textContent = 'Looking for a code...';
    scanTimer = setTimeout(detect, 3800); // demo only: the real camera scan replaces this in the app
  }
  function detect() {
    if (detecting || current !== 'scan') return;
    detecting = true; clearTimeout(scanTimer);
    frame.classList.add('found'); status.textContent = 'Code found. Opening check-in...';
    setTimeout(() => go('result'), 1100);
  }
  frame.onclick = detect;
  $('#closeScan').onclick = () => { go('login'); toast('Logged out'); };
  $('#light').onclick = e => {
    const on = e.currentTarget.classList.toggle('on');
    $('#glow').classList.toggle('on', on);
    e.currentTarget.textContent = on ? 'Turn off light' : 'Turn on light';
  };

  /* ---------- P3 shared check-in (sample data) ---------- */
  const OPT = ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'];
  const LBL = ['Little interest in things', 'Feeling down', 'Trouble sleeping', 'Feeling tired', 'Nervous or on edge', 'Hard to stop worrying', 'Trouble relaxing', 'Feeling bad about themselves', 'Thoughts of self-harm'];
  const SAMPLES = [
    { level: 'Some stress', bars: 2, a: [0, 1, 2, 1, 1, 1, 1, 0, 0], s: 'Talk with someone they trust and consider professional support.' },
    { level: 'Doing okay', bars: 1, a: [0, 1, 1, 0, 1, 0, 0, 0, 0], s: 'Keep up routines that help them feel well. A check-in again in a couple of weeks may help.' },
    { level: 'A lot on their mind', bars: 3, a: [2, 3, 3, 2, 2, 3, 2, 2, 1], s: 'A conversation with a professional soon would help. Check in with them about how they feel today.' }
  ];
  const fmt = d => d.toLocaleDateString('en-PH', { month: 'short', day: 'numeric', year: 'numeric' });
  function renderResult() {
    const d = SAMPLES[sampleIdx % SAMPLES.length]; sampleIdx++;
    const now = new Date(), end = new Date(now.getTime() + 15 * 864e5);
    $('#dates').textContent = `Shared on ${fmt(now)} · Code ends ${fmt(end)}`;
    $('#level').textContent = d.level; $('#sugg').textContent = d.s;
    $$('#meter i').forEach((el, i) => { el.classList.remove('on'); el.style.setProperty('--i', i); void el.offsetWidth; if (i < d.bars) el.classList.add('on'); });
    const rows = d.a.map((v, i) => ({ i, v })).sort((x, y) => y.v - x.v || x.i - y.i);
    const li = (r, k) => `<li style="--k:${k}"><span>${LBL[r.i]}</span><b>${OPT[r.v]}</b></li>`;
    $('#top').innerHTML = rows.slice(0, 3).map((r, k) => li(r, k)).join('');
    $('#rest').innerHTML = rows.slice(3).map((r, k) => li(r, k)).join('');
    $('#risk').hidden = !(d.a[8] > 0);
    $('#moreWrap').classList.remove('open');
    $('#seeAll').textContent = 'See all answers'; $('#seeAll').setAttribute('aria-expanded', 'false');
  }
  $('#seeAll').onclick = e => {
    const open = $('#moreWrap').classList.toggle('open');
    e.currentTarget.textContent = open ? 'Show fewer answers' : 'See all answers';
    e.currentTarget.setAttribute('aria-expanded', open);
  };
  $('#again').onclick = () => go('scan');
})();