(() => {
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const screens = $$('.screen'), nav = $('#nav');
  const TABS = ['home', 'quiz', 'help', 'share', 'result'];
  let current = 'splash', answers = [], qi = 0, level = null, qrExpiry = null;

  /* ---------- navigation ---------- */
  function go(name) {
    if (name === current) return;
    const from = $(`[data-screen="${current}"]`), to = $(`[data-screen="${name}"]`);
    from.classList.add('leaving'); from.classList.remove('active');
    setTimeout(() => from.classList.remove('leaving'), 460);
    to.classList.add('active');
    current = name;
    nav.classList.toggle('show', TABS.includes(name));
    $$('button', nav).forEach(b => b.classList.toggle('on', b.dataset.tab === (name === 'result' ? 'quiz' : name)));
    const sc = $('.scroll', to); if (sc) sc.scrollTop = 0;
    if (name === 'quiz') startQuiz();
    if (name === 'result') showResult();
    if (name === 'help') initMap();
    if (name === 'intro') resetIntro();
  }

  /* sheets */
  const sheetFor = id => ({ sheet: $('#' + id), bd: $('#' + id + '-bd') });
  function openSheet(id) { const { sheet, bd } = sheetFor(id); sheet.classList.add('show'); bd && bd.classList.add('show'); if (id === 'consent') { const t = $('#terms'); t.scrollTop = 0; } }
  function closeSheet(id) { const { sheet, bd } = sheetFor(id); sheet.classList.remove('show'); bd && bd.classList.remove('show'); }

  document.addEventListener('click', e => {
    const t = e.target.closest('[data-go],[data-open],[data-close]'); if (t) {
      if (t.dataset.close) closeSheet(t.dataset.close);
      if (t.dataset.open) openSheet(t.dataset.open);
      if (t.dataset.go) {
        const dest = t.dataset.go;
        setTimeout(() => go(dest), t.dataset.close ? 250 : 0);
      }
      return;
    }
    if (e.target.classList.contains('sheet-backdrop')) closeSheet(e.target.id.replace('-bd', ''));
  });

  /* ---------- terms & conditions ---------- */
  (function renderTerms() {
    const T = window.MUNI_TERMS, box = $('#terms'); if (!T || !box) return;
    const chev = '<svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>';
    const esc = t => t.replace(/&/g, '&amp;').replace(/</g, '&lt;');
    let html = '<div class="terms-lead">' + T.lead.map(p => `<p>${esc(p)}</p>`).join('') + '</div>';
    T.sections.forEach((s, i) => {
      const body = s.b.map(([k, v], n) => (k === 'p' ? `<p style="--k:${n}">${esc(v)}</p>` : `<ul style="--k:${n}">${v.map(x => `<li>${esc(x)}</li>`).join('')}</ul>`)).join('');
      html += `<div class="acc${i === 0 ? ' open' : ''}" style="--i:${i}"><button class="acc-h" aria-expanded="${i === 0}"><span>${i + 1}. ${esc(s.t)}</span>${chev}</button><div class="acc-b"><div class="acc-in"><div class="acc-pad">${body}</div></div></div></div>`;
    });
    html += '<div class="terms-end">' + T.end.map(p => `<p>${esc(p)}</p>`).join('') + '</div>';
    box.innerHTML = html;
    box.addEventListener('click', e => {
      const h = e.target.closest('.acc-h'); if (!h) return;
      const acc = h.parentElement, open = !acc.classList.contains('open');
      acc.classList.toggle('open', open); h.setAttribute('aria-expanded', open);
      if (open) setTimeout(() => acc.scrollIntoView({ behavior: 'smooth', block: 'nearest' }), 380);
    });
  })();

  /* ---------- mascot introduction ---------- */
  const iLines = $$('#introLines p'), iDots = $('#introDots'), iNext = $('#introNext'), pop = $('#popWrap');
  let step = 0;
  iLines.forEach(() => iDots.appendChild(document.createElement('i')));
  function setStep(n, hop) {
    iLines.forEach((p, i) => { p.classList.toggle('on', i === n); p.classList.toggle('off', i < n); });
    $$('i', iDots).forEach((d, i) => d.classList.toggle('on', i === n));
    iNext.textContent = n === iLines.length - 1 ? "Let's go" : 'Next';
    step = n;
    if (hop) { pop.classList.remove('hop'); void pop.offsetWidth; pop.classList.add('hop'); }
  }
  function resetIntro() { setStep(0, false); }
  iNext.onclick = () => (step < iLines.length - 1 ? setStep(step + 1, true) : go('welcome'));
  setStep(0, false);

  /* ---------- splash ---------- */
  setTimeout(() => go('intro'), 2300);

  /* ---------- quiz ---------- */
  const opts = ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'];
  const Q = [
    'Over the last 2 weeks, how often have you felt little interest or pleasure in doing things?',
    'How often have you felt down, low, or hopeless?',
    'How often have you had trouble falling or staying asleep?',
    'How often have you felt tired or low on energy?',
    'How often have you felt nervous, anxious, or on edge?',
    'How often have you been unable to stop or control worrying?',
    'How often have you had trouble relaxing?',
    'How often have you felt bad about yourself?',
    'How often have you had thoughts that you would be better off not here, or of hurting yourself?'
  ];
  function startQuiz() { if (answers.length === Q.length) { answers = []; } qi = answers.length; renderQ(false); }
  function renderQ(animate = true) {
    const wrap = $('#qwrap');
    const draw = () => {
      $('#qtext').textContent = Q[qi];
      $('#qcount').textContent = `Question ${qi + 1} of ${Q.length}`;
      $('#qbar').style.width = ((qi + 1) / Q.length * 100) + '%';
      const o = $('#qopts'); o.innerHTML = '';
      opts.forEach((txt, i) => {
        const b = document.createElement('button');
        b.className = 'opt' + (answers[qi] === i ? ' sel' : ''); b.textContent = txt;
        b.onclick = () => { answers[qi] = i; $$('.opt', o).forEach(x => x.classList.remove('sel')); b.classList.add('sel'); $('#qnext').disabled = false; };
        o.appendChild(b);
      });
      $('#qnext').disabled = answers[qi] === undefined;
      $('#qnext').textContent = qi === Q.length - 1 ? 'See my result' : 'Next';
    };
    if (!animate) return draw();
    wrap.classList.add('out');
    setTimeout(() => { draw(); wrap.classList.replace('out', 'in'); requestAnimationFrame(() => requestAnimationFrame(() => wrap.classList.remove('in'))); }, 230);
  }
  $('#qnext').onclick = () => {
    if (qi < Q.length - 1) { qi++; renderQ(); }
    else { compute(); go('result'); }
  };
  $('#qback').onclick = () => { if (qi > 0) { qi--; renderQ(); } else go('home'); };

  /* ---------- result ---------- */
  const R = [
    { label: 'Doing okay', bars: 1, text: 'Your answers suggest things feel fairly steady lately. Check in again whenever you like.', next: ['Keep up routines that help you feel well.', 'Check in again in a couple of weeks.', 'Support is here if things change.'] },
    { label: 'Some stress', bars: 2, text: 'Your answers suggest you may be carrying some stress lately. That is common, and support is available.', next: ['Talk with someone you trust.', 'Consider speaking with a professional.', 'Try a short breathing exercise.'] },
    { label: 'A lot on your mind', bars: 3, text: 'Your answers suggest things may feel heavy right now. You deserve support, and reaching out is a strong step.', next: ['Please consider speaking with a professional soon.', 'Reach out to someone you trust today.', 'Use the help line below if you need to talk now.'] }
  ];
  function compute() {
    const sum = answers.reduce((a, b) => a + b, 0);
    level = sum <= 7 ? 0 : sum <= 16 ? 1 : 2;
    $('#latest').classList.remove('empty');
    $('#latest-label').textContent = R[level].label;
    $('#latest-sub').textContent = 'Sharing ends in 15 days';
    if (answers[8] > 0) setTimeout(() => openSheet('crisis'), 900);
  }
  function showResult() {
    const r = R[level === null ? 1 : level];
    $('#feel-label').textContent = r.label; $('#feel-text').textContent = r.text;
    $('#feel-next').innerHTML = r.next.map(n => `<li>${n}</li>`).join('');
    $$('#feel .meter i').forEach((el, i) => { el.classList.remove('on'); el.style.setProperty('--i', i); void el.offsetWidth; if (i < r.bars) el.classList.add('on'); });
  }

  /* ---------- facility locator (sample data) ---------- */
  const F = [
    { n: 'Ilocos Training & Regional Medical Center', t: 'hospital', a: 'Parian, San Fernando City', h: 'Open 24 hours', s: 'Psychiatry, emergency care', x: 46, y: 48 },
    { n: 'City Health Office – Counseling Desk', t: 'counseling', a: 'City Hall Compound, San Fernando', h: 'Mon–Fri, 8 AM–5 PM', s: 'Counseling, referrals', x: 30, y: 28 },
    { n: 'Wellness Mind Clinic', t: 'clinic', a: 'Quezon Ave., San Fernando', h: 'Mon–Sat, 9 AM–6 PM', s: 'Consultations, therapy', x: 72, y: 70 },
    { n: 'Barangay Care Counseling Center', t: 'counseling', a: 'Catbangen, San Fernando', h: 'Mon–Fri, 9 AM–4 PM', s: 'Peer and youth counseling', x: 80, y: 36 }
  ];
  let mapReady = false, sel = 0, filt = 'all', q = '';
  function initMap() {
    if (mapReady) return; mapReady = true;
    const map = $('#map');
    F.forEach((f, i) => {
      const p = document.createElement('button');
      p.className = 'pin'; p.style.left = f.x + '%'; p.style.top = f.y + '%'; p.style.animationDelay = (.15 * i) + 's';
      p.setAttribute('aria-label', f.n); p.onclick = () => select(i); map.appendChild(p);
    });
    $('#search').oninput = e => { q = e.target.value.toLowerCase(); refresh(); };
    $$('#chips button').forEach(b => b.onclick = () => { $$('#chips button').forEach(x => x.classList.remove('on')); b.classList.add('on'); filt = b.dataset.f; refresh(); });
    select(0, true);
  }
  const visible = f => (filt === 'all' || f.t === filt) && (f.n + f.a).toLowerCase().includes(q);
  function refresh() {
    const pins = $$('.pin'); let first = -1;
    F.forEach((f, i) => { const v = visible(f); pins[i].classList.toggle('hide', !v); if (v && first < 0) first = i; });
    if (first >= 0 && !visible(F[sel])) select(first); else if (first < 0) $('#fac').innerHTML = '<h3>No places found</h3><p>Try another area or choose All.</p>';
  }
  function select(i, instant) {
    sel = i; const f = F[i], card = $('#fac');
    $$('.pin').forEach((p, k) => p.classList.toggle('sel', k === i));
    const draw = () => {
      card.innerHTML = `<h3>${f.n}</h3><p>${f.a}<br>${f.h}<br>${f.s}</p><button class="btn dark" id="dir">Get directions</button>`;
      $('#dir').onclick = () => window.open('https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(f.n + ' ' + f.a), '_blank');
      card.classList.remove('swap');
    };
    if (instant) return draw();
    card.classList.add('swap'); setTimeout(draw, 220);
  }

  /* ---------- QR share ---------- */
  const agree = $('#agree'), gen = $('#gen');
  agree.onchange = () => gen.disabled = !agree.checked;
  gen.onclick = makeQR; $('#regen').onclick = makeQR;
  function makeQR() {
    if (!agree.checked) return;
    const token = crypto.getRandomValues(new Uint32Array(8));
    drawQR($('#qr'), token);
    qrExpiry = new Date(Date.now() + 15 * 864e5);
    $('#qrexp').textContent = 'Expires ' + qrExpiry.toLocaleDateString('en-PH', { month: 'long', day: 'numeric', year: 'numeric' });
    $('#consent-card').classList.add('done'); $('#qrcard').hidden = false;
    toast('Your code is ready');
  }
  function drawQR(c, seed) { // decorative demo pattern from a random token, not a scannable QR
    const ctx = c.getContext('2d'), N = 25, s = c.width / N;
    ctx.clearRect(0, 0, c.width, c.height); ctx.fillStyle = '#285943';
    let r = seed.reduce((a, b) => (a ^ b) >>> 0, 7);
    const rnd = () => (r = (r * 1664525 + 1013904223) >>> 0) / 4294967296;
    const finder = (x, y) => { ctx.fillRect(x * s, y * s, 7 * s, 7 * s); ctx.clearRect((x + 1) * s, (y + 1) * s, 5 * s, 5 * s); ctx.fillRect((x + 2) * s, (y + 2) * s, 3 * s, 3 * s); };
    const inF = (x, y) => (x < 8 && y < 8) || (x > N - 9 && y < 8) || (x < 8 && y > N - 9);
    for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) if (!inF(x, y) && rnd() > .52) { ctx.beginPath(); ctx.roundRect(x * s + .5, y * s + .5, s - 1, s - 1, 2); ctx.fill(); }
    finder(0, 0); finder(N - 7, 0); finder(0, N - 7);
  }

  /* ---------- toast ---------- */
  let tt; function toast(m) { const t = $('#toast'); t.textContent = m; t.classList.add('show'); clearTimeout(tt); tt = setTimeout(() => t.classList.remove('show'), 2200); }
})();