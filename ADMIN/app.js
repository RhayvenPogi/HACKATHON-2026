const $ = (s, r = document) => r.querySelector(s);
const ICON = {
  dashboard: '<path d="M3 11l9-8 9 8v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z"/>',
  manage: '<circle cx="9" cy="8" r="3.5"/><path d="M2 20c0-4 3-6 7-6s7 2 7 6M17 5a3 3 0 010 6M19 14c2 .7 3 2.5 3 5"/>',
  register: '<rect x="3" y="3" width="18" height="18" rx="4"/><path d="M12 8v8M8 12h8"/>',
  pending: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  verified: '<path d="M12 2l8 3v6c0 5-3.5 9-8 11-4.5-2-8-6-8-11V5z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/>',
  logout: '<path d="M10 3H5a2 2 0 00-2 2v14a2 2 0 002 2h5M16 8l4 4-4 4M20 12H9"/>'
};
const svg = (n, s = 22, st = 'currentColor') =>
  `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="${st}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICON[n]}</svg>`;

const NAV = [
  ['dashboard', 'Dashboard', 'dashboard'],
  ['management', 'Professional Management', 'manage'],
  ['pending', 'Pending Verification', 'pending'],
  ['verified', 'Verified Professionals', 'verified'],
  ['logout', 'Logout', 'logout']
];

let pros = [
  { id: 1, name: 'Dr. Maria Reyes', lic: 'PRC-123456', date: '2026-11-05', type: 'Psychiatrist', fac: 'Ilocos Training Hospital', email: 'm.reyes@example.com', status: 'pending' },
  { id: 2, name: 'Dr. James Dela Cruz', lic: 'PRC-789012', date: '2026-11-04', type: 'Psychologist', fac: 'San Fernando City Health Office', email: 'j.delacruz@example.com', status: 'pending' },
  { id: 3, name: 'Dr. Ana Santos', lic: 'PRC-345678', date: '2026-11-02', type: 'Clinical Psychologist', fac: 'Private clinic', email: 'a.santos@example.com', status: 'verified' },
  { id: 4, name: 'Jose Bautista', lic: 'PRC-456123', date: '2026-10-28', type: 'Guidance Counselor', fac: 'Community Center', email: 'j.bautista@example.com', status: 'verified' },
  { id: 5, name: 'Dr. Liza Ramos', lic: 'PRC-998877', date: '2026-10-20', type: 'Psychiatrist', fac: 'Ilocos Training Hospital', email: 'l.ramos@example.com', status: 'verified' },
  { id: 6, name: 'Mark Villanueva', lic: 'PRC-221133', date: '2026-10-15', type: 'Counselor', fac: 'Private clinic', email: 'm.villa@example.com', status: 'verified' },
  { id: 7, name: 'Dr. Carla Mendoza', lic: 'PRC-554433', date: '2026-10-02', type: 'Psychologist', fac: 'Wellness Center', email: 'c.mendoza@example.com', status: 'deactivated' }
];
let nextId = 8;

const ACTIVITY = {
  7: [42, 55, 48, 62, 58, 70, 66],
  30: [42, 85, 77, 113, 73, 103, 88, 109, 89, 125, 105, 133],
  90: [30, 48, 60, 72, 66, 90, 84, 110, 98, 120, 128, 140]
};
let range = 30, current = 'dashboard';

const fmt = d => new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
const count = s => pros.filter(p => p.status === s).length;
const tag = s => `<span class="tag ${s}">${{ pending: 'Pending', verified: 'Verified', deactivated: 'Deactivated', rejected: 'Rejected' }[s]}</span>`;
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/* ---------- Navigation ---------- */
function renderNav() {
  $('#nav').innerHTML = NAV.map(([id, label, ic]) =>
    `<button data-go="${id}" title="${label}" ${id === current ? 'aria-current="page"' : ''}>${svg(ic)}<span class="lbl">${label}</span>${id === 'pending' && count('pending') ? `<span class="badge">${count('pending')}</span>` : ''}</button>`).join('');
}
function go(v) {
  if (v === 'logout') return confirmLogout();
  current = v;
  closeMenus();
  renderNav();
  $('#view').innerHTML = VIEWS[v]();
  if (v === 'dashboard') drawChart();
  $('#view').focus({ preventScroll: true });
  window.scrollTo(0, 0);
}
function closeMenus() { $('#app').classList.remove('open'); $('#userMenu').hidden = true; $('#userBtn').setAttribute('aria-expanded', 'false'); syncBurger(); }

/* ---------- Views ---------- */
function rows(list, opts = {}) {
  if (!list.length) return `<tr><td colspan="5" class="empty">No professionals found.</td></tr>`;
  return list.map(p => `<tr>
    <td>${esc(p.name)}</td><td>${esc(p.lic)}</td><td>${fmt(p.date)}</td><td>${tag(p.status)}</td>
    <td><div class="row-acts">${p.status === 'pending'
      ? `<button class="btn sm soft" data-open="${p.id}">Review</button>`
      : `<button class="btn sm" data-open="${p.id}">View</button>`}</div></td></tr>`).join('');
}
const table = (list, head = ['Name', 'License No.', 'Date Submitted', 'Status', 'Action']) =>
  `<div class="scroll"><table><thead><tr>${head.map(h => `<th>${h}</th>`).join('')}</tr></thead><tbody id="tbody">${rows(list)}</tbody></table></div>`;

const VIEWS = {
  dashboard: () => `
    <div class="page-head"><div><h1>Dashboard</h1><p class="sub">Overview of mental health professionals and system activity.</p></div></div>
    <section class="stats">
      ${[['manage', 'Total Professionals', pros.length, 'management', '#3C74C4'], ['verified', 'Verified', count('verified'), 'verified', '#2F7048'],
         ['pending', 'Pending', count('pending'), 'pending', '#F2B84B'], ['logout', 'Deactivated', count('deactivated'), 'management', '#E8664F']]
        .map(([ic, l, n, to, c]) => `<button class="card stat" data-go="${to}"><span class="ico" style="--c:${c}">${svg(ic, 26, c)}</span><strong>${n}</strong><span>${l}</span></button>`).join('')}
    </section>
    <section class="charts">
      <div class="card chart-card">
        <div class="chart-top"><h2>System Activity</h2>
          <select id="range" aria-label="Date range"><option value="7">Last 7 Days</option><option value="30" selected>Last 30 Days</option><option value="90">Last 90 Days</option></select></div>
        <div id="chart"></div>
      </div>
      <div class="card chart-card">
        <h2>Assessment Distribution</h2>
        <div class="donut-wrap">
          <div class="donut" role="img" aria-label="Low 45%, Moderate 35%, High 20%"><b>100%</b></div>
          <ul class="legend">
            <li><i style="background:var(--leaf)"></i>Low<em>45%</em></li>
            <li><i style="background:var(--amber)"></i>Moderate<em>35%</em></li>
            <li><i style="background:var(--red)"></i>High<em>20%</em></li>
          </ul>
        </div>
        <p class="note">Anonymous totals only. Individual responses are never shown to administrators.</p>
      </div>
    </section>`,

  management: () => `
    <div class="page-head"><div><h1>Professional Management</h1><p class="sub">View, update, activate, or deactivate professional accounts.</p></div>
      <button class="btn primary" data-reg>Register Professional</button></div>
    <section class="card panel">
      <div class="panel-head"><h2>All professionals (<span id="n">${pros.length}</span>)</h2></div>
      <div class="tools">
        <input id="q" type="search" placeholder="Search by name or license number" aria-label="Search">
        <select id="f" aria-label="Status"><option value="">All statuses</option><option value="verified">Verified</option><option value="pending">Pending</option><option value="deactivated">Deactivated</option><option value="rejected">Rejected</option></select>
      </div>
      ${table(pros)}
    </section>`,

  pending: () => `
    <div class="page-head"><div><h1>Pending Verification</h1><p class="sub">Review submitted credentials before granting access.</p></div></div>
    <section class="card panel">${table(pros.filter(p => p.status === 'pending'))}</section>`,

  verified: () => `
    <div class="page-head"><div><h1>Verified Professionals</h1><p class="sub">Professionals authorized to scan MUNI QR codes.</p></div></div>
    <section class="card panel">${table(pros.filter(p => p.status === 'verified'))}</section>`,

  settings: () => `
    <div class="page-head"><div><h1>Account Settings</h1><p class="sub">Update your administrator profile and password.</p></div></div>
    <form class="card narrow" id="setForm">
      <div class="form">
        <label class="full">Display name<input value="Admin" required></label>
        <label>New password<input type="password" minlength="8" autocomplete="new-password"></label>
        <label>Confirm password<input type="password" minlength="8" autocomplete="new-password"></label>
        <div class="form-actions full"><button class="btn primary">Save changes</button></div>
      </div>
    </form>`
};

/* ---------- Chart ---------- */
function drawChart() {
  const d = ACTIVITY[range], W = 520, H = 230, l = 36, b = 28, t = 12, max = 150;
  const x = i => l + i * (W - l - 8) / (d.length - 1), y = v => t + (H - t - b) * (1 - v / max);
  const pts = d.map((v, i) => [x(i), y(v)]);
  const line = pts.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join(' ');
  const grid = [0, 50, 100, 150].map(v => `<line x1="${l}" x2="${W}" y1="${y(v)}" y2="${y(v)}" stroke="#E3EAE4"/><text x="${l - 8}" y="${y(v) + 4}" text-anchor="end" font-size="11" fill="#66756C">${v}</text>`).join('');
  $('#chart').innerHTML = `<svg class="line-chart" viewBox="0 0 ${W} ${H}" role="img" aria-label="System activity chart">
    <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#79A982" stop-opacity=".45"/><stop offset="1" stop-color="#79A982" stop-opacity="0"/></linearGradient></defs>
    ${grid}<path d="${line} L${x(d.length - 1)} ${y(0)} L${l} ${y(0)}Z" fill="url(#g)"/>
    <path d="${line}" fill="none" stroke="#4F8A65" stroke-width="2.5" stroke-linejoin="round"/>
    ${pts.map((p, i) => `<circle cx="${p[0]}" cy="${p[1]}" r="4" fill="#fff" stroke="#4F8A65" stroke-width="2"><title>${d[i]} sessions</title></circle>`).join('')}</svg>`;
}

/* ---------- Modal / toast ---------- */
function openModal(html) { $('#dialog').innerHTML = html; $('#modal').hidden = false; const f = $('#dialog button,#dialog input'); f && f.focus(); }
function closeModal() { $('#modal').hidden = true; }
let tt;
function toast(m) { const t = $('#toast'); t.textContent = m; t.classList.add('show'); clearTimeout(tt); tt = setTimeout(() => t.classList.remove('show'), 2400); }

function openPro(id) {
  const p = pros.find(x => x.id === id);
  const acts = {
    pending: `<button class="btn danger" data-act="reject" data-id="${id}">Reject</button><button class="btn primary" data-act="approve" data-id="${id}">Approve and create account</button>`,
    verified: `<button class="btn danger" data-act="deactivate" data-id="${id}">Deactivate</button>`,
    deactivated: `<button class="btn primary" data-act="activate" data-id="${id}">Activate</button>`,
    rejected: `<button class="btn" data-act="reopen" data-id="${id}">Move back to pending</button>`
  }[p.status];
  openModal(`<h2>${esc(p.name)} ${tag(p.status)}</h2><p class="sub">${esc(p.type)}</p>
    <dl class="dl"><dt>License no.</dt><dd>${esc(p.lic)}</dd><dt>Facility</dt><dd>${esc(p.fac)}</dd><dt>Email</dt><dd>${esc(p.email)}</dd><dt>Submitted</dt><dd>${fmt(p.date)}</dd></dl>
    ${p.status === 'pending' ? `<label class="check"><input type="checkbox"> Name matches the PRC ID</label><label class="check"><input type="checkbox"> License is valid and active</label><label class="check"><input type="checkbox"> Facility affiliation confirmed</label>` : ''}
    <div class="form-actions"><button class="btn" data-close>Close</button>${acts}</div>`);
}
function openRegister() {
  openModal(`<h2>Register Professional</h2><p class="sub">Add a professional and submit their credentials for verification.</p>
    <form id="regForm" class="form modal-form">
      <label>Full name<input name="name" required></label>
      <label>Profession<select name="type"><option>Psychiatrist</option><option>Psychologist</option><option>Clinical Psychologist</option><option>Guidance Counselor</option><option>Counselor</option></select></label>
      <label>PRC license number<input name="lic" required placeholder="PRC-000000"></label>
      <label>Email<input name="email" type="email" required></label>
      <label class="full">Facility<input name="fac" required></label>
      <label class="full">Credential document<input type="file" accept=".pdf,.jpg,.png"></label>
      <div class="form-actions full"><button type="button" class="btn" data-close>Cancel</button><button class="btn primary">Submit for verification</button></div>
    </form>`);
}
function confirmLogout() {
  closeMenus();
  openModal(`<h2>Log out?</h2><p class="sub">You will need to sign in again to manage professionals.</p>
    <div class="form-actions"><button class="btn" data-close>Cancel</button><button class="btn primary" data-act="logout">Logout</button></div>`);
}

function act(a, id) {
  const p = pros.find(x => x.id === id);
  const map = { approve: ['verified', 'approved. Login details will be emailed.'], reject: ['rejected', 'rejected.'], deactivate: ['deactivated', 'deactivated.'], activate: ['verified', 'activated.'], reopen: ['pending', 'moved to pending.'] };
  p.status = map[a][0];
  closeModal();
  toast(`${p.name} ${map[a][1]}`);
  go(current);
}

/* ---------- Events ---------- */
document.addEventListener('click', e => {
  const t = e.target.closest('[data-go],[data-open],[data-act],[data-close],[data-reg]');
  if (e.target.id === 'modal') return closeModal();
  if (!e.target.closest('.user')) $('#userMenu').hidden = true;
  if (!t) return;
  if (t.hasAttribute('data-reg')) return openRegister();
  if (t.dataset.go) return go(t.dataset.go);
  if (t.dataset.open) return openPro(+t.dataset.open);
  if (t.hasAttribute('data-close')) return closeModal();
  if (t.dataset.act === 'logout') { closeModal(); $('#login').hidden = false; return; }
  act(t.dataset.act, +t.dataset.id);
});
document.addEventListener('click', e => {
  if (!e.target.closest('#pwToggle')) return;
  const pw = $('#pw'), show = pw.type === 'password';
  pw.type = show ? 'text' : 'password';
  e.target.textContent = show ? 'Hide' : 'Show';
  e.target.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
});
$('#userBtn').onclick = () => { const m = $('#userMenu'); m.hidden = !m.hidden; $('#userBtn').setAttribute('aria-expanded', !m.hidden); };
const mobile = () => window.matchMedia('(max-width:860px)').matches;
function toggleSide(force) {
  const app = $('#app');
  if (mobile()) app.classList.toggle('open', force);
  else app.classList.toggle('collapsed', force === undefined ? undefined : !force);
  const open = mobile() ? app.classList.contains('open') : !app.classList.contains('collapsed');
  $('#burger').setAttribute('aria-expanded', open);
}
$('#burger').onclick = () => toggleSide();
$('#scrim').onclick = closeMenus;
document.addEventListener('keydown', e => { if (e.key === 'Escape') { closeModal(); closeMenus(); } });

document.addEventListener('input', e => {
  if (e.target.id === 'q' || e.target.id === 'f') {
    const q = $('#q').value.toLowerCase(), f = $('#f').value;
    const list = pros.filter(p => (!f || p.status === f) && (p.name + p.lic).toLowerCase().includes(q));
    $('#tbody').innerHTML = rows(list); $('#n').textContent = list.length;
  }
});
document.addEventListener('change', e => { if (e.target.id === 'range') { range = +e.target.value; drawChart(); } });
document.addEventListener('submit', e => {
  e.preventDefault();
  if (e.target.id === 'regForm') {
    const d = Object.fromEntries(new FormData(e.target));
    pros.push({ id: nextId++, name: d.name, lic: d.lic, type: d.type, fac: d.fac, email: d.email, date: new Date().toISOString().slice(0, 10), status: 'pending' });
    closeModal(); toast('Submitted. Added to Pending Verification.'); go(current);
  } else if (e.target.id === 'setForm') toast('Changes saved.');
  else if (e.target.id === 'loginForm') {
    const b = e.target.querySelector('.btn');
    b.classList.add('loading'); b.querySelector('.txt').textContent = 'Signing in…';
    setTimeout(() => { b.classList.remove('loading'); b.querySelector('.txt').textContent = 'Sign in'; e.target.reset(); $('#login').hidden = true; go('dashboard'); toast('Welcome back, Admin.'); }, 800);
  }
});

const syncBurger = () => $('#burger').setAttribute('aria-expanded', mobile() ? $('#app').classList.contains('open') : !$('#app').classList.contains('collapsed'));
window.addEventListener('resize', syncBurger);
syncBurger();
go('dashboard');