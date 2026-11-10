'use strict';

const API = '/portal/api/';
const $ = (s, r = document) => r.querySelector(s);
const ICON = {
  dashboard: '<path d="M3 11l9-8 9 8v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z"/>',
  manage: '<circle cx="9" cy="8" r="3.5"/><path d="M2 20c0-4 3-6 7-6s7 2 7 6M17 5a3 3 0 010 6M19 14c2 .7 3 2.5 3 5"/>',
  register: '<rect x="3" y="3" width="18" height="18" rx="4"/><path d="M12 8v8M8 12h8"/>',
  pending: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  verified: '<path d="M12 2l8 3v6c0 5-3.5 9-8 11-4.5-2-8-6-8-11V5z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/>',
  logout: '<path d="M10 3H5a2 2 0 00-2 2v14a2 2 0 002 2h5M16 8l4 4-4 4M20 12H9"/>',
  facility: '<path d="M12 21s-7-6.2-7-11a7 7 0 0114 0c0 4.8-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>'
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

const STATUS_LABEL = { pending: 'Pending', verified: 'Verified', deactivated: 'Deactivated', rejected: 'Rejected' };
const DONE = { reject: 'rejected.', reopen: 'moved back to pending.', deactivate: 'deactivated.', activate: 'activated.' };
const FIELD_LABEL = {
  full_name: 'Full name', username: 'Username', profession: 'Profession',
  prc_license_number: 'PRC license number', prc_license_expiry: 'PRC license expiry',
  facility_name: 'Facility', contact_email: 'Email', contact_number: 'Contact number',
  current_password: 'Current password', new_password: 'New password', confirm_password: 'Confirm password',
  name: 'Name', facility_type: 'Type', address: 'Address', latitude: 'Latitude', longitude: 'Longitude',
  hours: 'Hours', source_note: 'Source', __all__: ''
};
const MAP_CENTER = [16.6159, 120.3166]; // San Fernando City, La Union
const TILE_URL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_ATTR = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
const PALETTE = ['var(--leaf)', 'var(--blue)', 'var(--amber)', 'var(--fresh)', 'var(--offc)'];

let me = null, pros = [], dash = null, range = 30, current = 'dashboard';
let facilities = [], facTypes = [], facMap = null, pickMap = null;

const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmt = d => new Date(`${d}T00:00:00`).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
const count = s => pros.filter(p => p.status === s).length;
const tag = s => `<span class="tag ${s}">${STATUS_LABEL[s]}</span>`;

/* ---------- Server ---------- */
function csrfToken() {
  const m = document.cookie.match(/(?:^|;\s*)csrftoken=([^;]+)/);
  return m ? decodeURIComponent(m[1]) : '';
}

async function api(path, { method = 'GET', body, auth = true } = {}) {
  let res;
  try {
    res = await fetch(API + path, {
      method,
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-CSRFToken': csrfToken() },
      body: body === undefined ? undefined : JSON.stringify(body)
    });
  } catch {
    throw Object.assign(new Error('Could not reach the server. Is runserver running?'), { status: 0, fields: {} });
  }
  let data = {};
  try { data = await res.json(); } catch { /* non-JSON body */ }
  if (res.status === 401 && auth) showLogin();
  if (!res.ok) {
    throw Object.assign(new Error(data.error || `Request failed (${res.status}).`), { status: res.status, fields: data.fields || {} });
  }
  return data;
}

const errorList = (fields = {}) => {
  const items = Object.entries(fields).flatMap(([k, msgs]) =>
    msgs.map(m => `<li>${FIELD_LABEL[k] ? `<b>${FIELD_LABEL[k]}:</b> ` : ''}${esc(m)}</li>`));
  return items.length ? `<ul class="field-errors">${items.join('')}</ul>` : '';
};

/* ---------- Session ---------- */
function showLogin() {
  me = null;
  closeModal();
  $('#app').hidden = true;
  $('#login').hidden = false;
  $('#loginForm').elements.user.focus();
}
function signedIn(data) {
  me = data;
  $('#userName').textContent = data.name;
  $('#avatar').textContent = data.initials;
  $('#login').hidden = true;
  $('#app').hidden = false;
  go('dashboard');
}
async function boot() {
  try { signedIn(await api('me/', { auth: false })); } catch { showLogin(); }
}
async function logout() {
  try { await api('logout/', { method: 'POST', auth: false }); } catch { /* signed out locally anyway */ }
  showLogin();
}

/* ---------- Navigation ---------- */
function renderNav() {
  $('#nav').innerHTML = NAV.map(([id, label, ic]) =>
    `<button data-go="${id}" title="${label}" ${id === current ? 'aria-current="page"' : ''}>${svg(ic)}<span class="lbl">${label}</span>${id === 'pending' && count('pending') ? `<span class="badge">${count('pending')}</span>` : ''}</button>`).join('');
}
async function go(v) {
  if (v === 'logout') return confirmLogout();
  closeMenus();
  try {
    if (v !== 'settings') pros = (await api('professionals/')).professionals;
    if (v === 'dashboard') dash = await api(`dashboard/?range=${range}`);
  } catch (e) {
    if (e.status !== 401) toast(e.message);
    return;
  }
  current = v;
  renderNav();
  if (facMap) { facMap.remove(); facMap = null; }
  $('#view').innerHTML = VIEWS[v]();
  if (v === 'dashboard') drawChart();
  if (v === 'facilities') drawFacilityMap();
  $('#view').focus({ preventScroll: true });
  window.scrollTo(0, 0);
}
function closeMenus() { $('#app').classList.remove('open'); $('#userMenu').hidden = true; $('#userBtn').setAttribute('aria-expanded', 'false'); syncBurger(); }

/* ---------- Views ---------- */
function rows(list) {
  if (!list.length) return `<tr><td colspan="5" class="empty">No professionals found.</td></tr>`;
  return list.map(p => `<tr>
    <td>${esc(p.name)}</td><td>${esc(p.lic)}</td><td>${fmt(p.date)}</td><td>${tag(p.status)}</td>
    <td><div class="row-acts"><button class="btn sm ${p.status === 'pending' ? 'soft' : ''}" data-open="${esc(p.id)}">${p.status === 'pending' ? 'Review' : 'View'}</button></div></td></tr>`).join('');
}
const table = (list, head = ['Name', 'License No.', 'Date Registered', 'Status', 'Action']) =>
  `<div class="scroll"><table><thead><tr>${head.map(h => `<th>${h}</th>`).join('')}</tr></thead><tbody id="tbody">${rows(list)}</tbody></table></div>`;

function donut() {
  const list = dash.professions, total = list.reduce((s, r) => s + r.count, 0);
  let acc = 0;
  const stops = total
    ? list.map((r, i) => { const a = acc; acc += r.count / total * 100; return `${PALETTE[i % PALETTE.length]} ${a}% ${acc}%`; }).join(',')
    : 'var(--line) 0 100%';
  const label = list.map(r => `${r.label} ${r.count}`).join(', ') || 'No active professionals';
  const legend = list.length
    ? list.map((r, i) => `<li><i style="background:${PALETTE[i % PALETTE.length]}"></i>${esc(r.label)}<em>${r.count}</em></li>`).join('')
    : '<li>No active professionals yet</li>';
  return `<div class="donut-wrap"><div class="donut" role="img" aria-label="${esc(label)}" style="background:conic-gradient(${stops})"><b>${total}</b></div><ul class="legend">${legend}</ul></div>`;
}

const VIEWS = {
  dashboard: () => `
    <div class="page-head"><div><h1>Dashboard</h1><p class="sub">Overview of registered mental health professionals.</p></div></div>
    <section class="stats">
      ${[['manage', 'Total Professionals', pros.length, 'management', '#3C74C4'], ['verified', 'Verified', count('verified'), 'verified', '#2F7048'],
         ['pending', 'Pending', count('pending'), 'pending', '#F2B84B'], ['logout', 'Deactivated', count('deactivated'), 'management', '#E8664F']]
        .map(([ic, l, n, to, c]) => `<button class="card stat" data-go="${to}"><span class="ico" style="--c:${c}">${svg(ic, 26, c)}</span><strong>${n}</strong><span>${l}</span></button>`).join('')}
    </section>
    <section class="charts">
      <div class="card chart-card">
        <div class="chart-top"><h2>Registrations</h2>
          <select id="range" aria-label="Date range">${[7, 30, 90].map(r => `<option value="${r}" ${r === range ? 'selected' : ''}>Last ${r} Days</option>`).join('')}</select></div>
        <div id="chart"></div>
        <p class="note">New professional registrations per ${dash.activity.bucket_days === 7 ? 'week' : 'day'}.</p>
      </div>
      <div class="card chart-card">
        <h2>Active Professionals by Profession</h2>
        ${donut()}
        <p class="note">${dash.expiring_soon} active license(s) expired or expiring within 60 days. Administrators have no access to citizen assessments.</p>
      </div>
    </section>`,

  management: () => `
    <div class="page-head"><div><h1>Professional Management</h1><p class="sub">View, approve, activate, or deactivate professional accounts.</p></div>
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
    <div class="page-head"><div><h1>Pending Verification</h1><p class="sub">Check credentials against PRC records before granting access.</p></div></div>
    <section class="card panel">${table(pros.filter(p => p.status === 'pending'))}</section>`,

  verified: () => `
    <div class="page-head"><div><h1>Verified Professionals</h1><p class="sub">Professionals authorized to scan MUNI QR codes.</p></div></div>
    <section class="card panel">${table(pros.filter(p => p.status === 'verified'))}</section>`,

  facilities: () => `
    <div class="page-head"><div><h1>Facilities</h1><p class="sub">Mental health facilities shown in the Muni app. Only verified, visible facilities appear to citizens.</p></div>
      <button class="btn primary" data-addfac>Add facility</button></div>
    <section class="card panel">
      <div class="panel-head"><h2>All facilities (${facilities.length})</h2></div>
      <div id="facMap" class="fac-map"></div>
      <div class="scroll"><table><thead><tr><th>Name</th><th>Type</th><th>Status</th><th>Updated</th><th>Action</th></tr></thead>
      <tbody>${facilities.length ? facilities.map(f => `<tr><td>${esc(f.name)}</td><td>${esc(f.type)}</td><td>${facTag(f)}</td><td>${fmt(f.updated)}</td>
        <td><div class="row-acts"><button class="btn sm" data-fac="${esc(f.id)}">Edit</button></div></td></tr>`).join('')
        : '<tr><td colspan="5" class="empty">No facilities yet. Add one from a verified source.</td></tr>'}</tbody></table></div>
    </section>`,

  settings: () => `
    <div class="page-head"><div><h1>Account Settings</h1><p class="sub">Update your administrator profile and password.</p></div></div>
    <form class="card narrow" id="setForm">
      <div class="form">
        <label class="full">Display name<input name="display_name" value="${esc(me.name)}" maxlength="150" required></label>
        <label class="full">Current password<input name="current_password" type="password" autocomplete="current-password"></label>
        <label>New password<input name="new_password" type="password" minlength="8" autocomplete="new-password"></label>
        <label>Confirm password<input name="confirm_password" type="password" minlength="8" autocomplete="new-password"></label>
        <p class="note full">Leave the password fields empty to keep your current password.</p>
        <div id="setErrors" class="full"></div>
        <div class="form-actions full"><button class="btn primary">Save changes</button></div>
      </div>
    </form>`
};

/* ---------- Chart ---------- */
function drawChart() {
  const { labels, values } = dash.activity;
  const W = 520, H = 230, l = 36, b = 28, t = 12, n = values.length;
  const top = Math.max(4, Math.ceil(Math.max(...values) / 4) * 4);
  const x = i => (n === 1 ? (l + W) / 2 : l + i * (W - l - 8) / (n - 1));
  const y = v => t + (H - t - b) * (1 - v / top);
  const pts = values.map((v, i) => [x(i), y(v)]);
  const line = pts.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join(' ');
  const grid = [0, top / 4, top / 2, top * 3 / 4, top].map(v =>
    `<line x1="${l}" x2="${W}" y1="${y(v)}" y2="${y(v)}" stroke="#E3EAE4"/><text x="${l - 8}" y="${y(v) + 4}" text-anchor="end" class="chart-axis">${v}</text>`).join('');
  const total = values.reduce((s, v) => s + v, 0);
  $('#chart').innerHTML = `<svg class="line-chart" viewBox="0 0 ${W} ${H}" role="img" aria-label="${total} registrations in the last ${range} days">
    <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#79A982" stop-opacity=".45"/><stop offset="1" stop-color="#79A982" stop-opacity="0"/></linearGradient></defs>
    ${grid}<path d="${line} L${x(n - 1)} ${y(0)} L${x(0)} ${y(0)}Z" fill="url(#g)"/>
    <path d="${line}" fill="none" stroke="#4F8A65" stroke-width="2.5" stroke-linejoin="round"/>
    ${pts.map((p, i) => `<circle cx="${p[0]}" cy="${p[1]}" r="4" fill="#fff" stroke="#4F8A65" stroke-width="2"><title>${fmt(labels[i])}: ${values[i]}</title></circle>`).join('')}
    <text x="${x(0)}" y="${H - 6}" class="chart-axis">${fmt(labels[0])}</text>
    <text x="${x(n - 1)}" y="${H - 6}" text-anchor="end" class="chart-axis">${fmt(labels[n - 1])}</text></svg>`;
}

/* ---------- Facilities ---------- */
const facTag = f => !f.is_active ? '<span class="tag deactivated">Hidden</span>'
  : f.is_verified ? '<span class="tag verified">Verified</span>' : '<span class="tag pending">Unverified</span>';
const hasLeaflet = () => typeof window.L !== 'undefined';
const tiles = () => L.tileLayer(TILE_URL, { maxZoom: 19, attribution: TILE_ATTR });

function drawFacilityMap() {
  const el = $('#facMap');
  if (!el) return;
  if (!hasLeaflet()) { el.innerHTML = '<p class="empty">Map could not load (no internet?). The list below still works.</p>'; return; }
  facMap = L.map(el).setView(MAP_CENTER, 13);
  tiles().addTo(facMap);
  const points = facilities.map(f => {
    const m = L.circleMarker([f.latitude, f.longitude], {
      radius: 9, weight: 2, color: '#285943',
      fillColor: !f.is_active ? '#9AA59F' : f.is_verified ? '#4F8A65' : '#F2B84B', fillOpacity: 0.9
    }).addTo(facMap);
    m.bindTooltip(f.name);
    m.on('click', () => openFacility(f.id));
    return [f.latitude, f.longitude];
  });
  if (points.length) facMap.fitBounds(points, { padding: [40, 40], maxZoom: 15 });
}

function openFacility(id) {
  const f = id ? facilities.find(x => x.id === id) : null;
  if (id && !f) return;
  const v = f || { name: '', facility_type: facTypes[0]?.value, address: '', latitude: '', longitude: '', contact_number: '', hours: '', source_note: '', is_verified: false, is_active: true };
  const opts = facTypes.map(t => `<option value="${esc(t.value)}" ${t.value === v.facility_type ? 'selected' : ''}>${esc(t.label)}</option>`).join('');
  openModal(`<h2>${f ? 'Edit facility' : 'Add facility'}</h2><p class="sub">Only add facilities confirmed by an official source.</p>
    <form id="facForm" class="form modal-form" data-id="${f ? esc(f.id) : ''}">
      <label class="full">Name<input name="name" required maxlength="200" value="${esc(v.name)}"></label>
      <label>Type<select name="facility_type">${opts}</select></label>
      <label>Contact number<input name="contact_number" maxlength="40" value="${esc(v.contact_number)}" placeholder="Optional"></label>
      <label class="full">Address<input name="address" required maxlength="300" value="${esc(v.address)}"></label>
      <div class="full"><span class="map-hint">Click the map or drag the pin to set the exact location.</span><div id="pickMap" class="pick-map"></div></div>
      <label>Latitude<input name="latitude" required inputmode="decimal" value="${v.latitude}"></label>
      <label>Longitude<input name="longitude" required inputmode="decimal" value="${v.longitude}"></label>
      <label class="full">Hours<input name="hours" maxlength="120" value="${esc(v.hours)}" placeholder="e.g. Mon-Fri 8:00 AM - 5:00 PM (optional)"></label>
      <label class="full">Source<input name="source_note" maxlength="300" value="${esc(v.source_note)}" placeholder="e.g. City Health Office list, checked 2026-11-20"></label>
      <div class="full check-row">
        <label class="check"><input type="checkbox" name="is_verified" ${v.is_verified ? 'checked' : ''}> Verified (shown in the app)</label>
        <label class="check"><input type="checkbox" name="is_active" ${v.is_active ? 'checked' : ''}> Visible</label>
      </div>
      <div id="facErrors" class="full"></div>
      <div class="form-actions full">${f ? '<button type="button" class="btn danger" data-facdel>Delete</button>' : ''}<button type="button" class="btn" data-close>Cancel</button><button class="btn primary">Save</button></div>
    </form>`);
  setTimeout(initPicker, 60);
}

function initPicker() {
  const el = $('#pickMap'), form = $('#facForm');
  if (!el || !form) return;
  if (!hasLeaflet()) { el.innerHTML = '<p class="empty">Map unavailable. Enter latitude and longitude manually.</p>'; return; }
  const lat = parseFloat(form.elements.latitude.value), lng = parseFloat(form.elements.longitude.value);
  const has = Number.isFinite(lat) && Number.isFinite(lng);
  pickMap = L.map(el).setView(has ? [lat, lng] : MAP_CENTER, has ? 17 : 14);
  tiles().addTo(pickMap);
  let pin = null;
  const place = (p, pan) => {
    if (!pin) {
      pin = L.marker(p, { draggable: true }).addTo(pickMap);
      pin.on('dragend', () => place(pin.getLatLng(), false));
    } else pin.setLatLng(p);
    form.elements.latitude.value = (+p.lat).toFixed(6);
    form.elements.longitude.value = (+p.lng).toFixed(6);
    if (pan) pickMap.panTo(p);
  };
  if (has) place({ lat, lng }, false);
  pickMap.on('click', e => place(e.latlng, false));
  const fromInputs = () => {
    const a = parseFloat(form.elements.latitude.value), b = parseFloat(form.elements.longitude.value);
    if (Number.isFinite(a) && Number.isFinite(b)) {
      if (!pin) { pin = L.marker([a, b], { draggable: true }).addTo(pickMap); pin.on('dragend', () => place(pin.getLatLng(), false)); }
      else pin.setLatLng([a, b]);
      pickMap.panTo([a, b]);
    }
  };
  form.elements.latitude.addEventListener('change', fromInputs);
  form.elements.longitude.addEventListener('change', fromInputs);
  pickMap.invalidateSize();
}

async function deleteFacility(btn) {
  if (btn.dataset.armed !== '1') { btn.dataset.armed = '1'; btn.textContent = 'Click again to delete'; return; }
  const id = $('#facForm').dataset.id;
  btn.disabled = true;
  try {
    await api(`facilities/${id}/delete/`, { method: 'POST' });
    closeModal(); toast('Facility deleted.'); go('facilities');
  } catch (e) { btn.disabled = false; if (e.status !== 401) toast(e.message); }
}

/* ---------- Modal / toast ---------- */
function openModal(html, sticky = false) {
  if (pickMap) { pickMap.remove(); pickMap = null; }
  $('#dialog').innerHTML = html;
  $('#modal').hidden = false;
  if (sticky) $('#modal').dataset.sticky = '1'; else delete $('#modal').dataset.sticky;
  const f = $('#dialog button,#dialog input'); f && f.focus();
}
function closeModal() {
  if (pickMap) { pickMap.remove(); pickMap = null; }
  $('#modal').hidden = true; delete $('#modal').dataset.sticky;
}
let tt;
function toast(m) { const t = $('#toast'); t.textContent = m; t.classList.add('show'); clearTimeout(tt); tt = setTimeout(() => t.classList.remove('show'), 2600); }

function openPro(id) {
  const p = pros.find(x => x.id === id);
  if (!p) return;
  const acts = {
    pending: `<button class="btn danger" data-act="reject" data-id="${id}">Reject</button><button class="btn primary" id="approveBtn" data-act="approve" data-id="${id}" disabled>Approve and create account</button>`,
    verified: `<button class="btn" data-act="reset_password" data-id="${id}">Reset password</button><button class="btn danger" data-act="deactivate" data-id="${id}">Deactivate</button>`,
    deactivated: `<button class="btn primary" data-act="activate" data-id="${id}">Activate</button>`,
    rejected: `<button class="btn" data-act="reopen" data-id="${id}">Move back to pending</button>`
  }[p.status];
  const expiry = `${fmt(p.expiry)}${p.license_current ? '' : ' <span class="tag rejected">Expired</span>'}`;
  openModal(`<h2>${esc(p.name)} ${tag(p.status)}</h2><p class="sub">${esc(p.type)}</p>
    <dl class="dl"><dt>Username</dt><dd>${esc(p.username)}</dd><dt>License no.</dt><dd>${esc(p.lic)}</dd><dt>License expiry</dt><dd>${expiry}</dd>
      <dt>Facility</dt><dd>${esc(p.fac)}</dd><dt>Email</dt><dd>${esc(p.email)}</dd>${p.phone ? `<dt>Contact no.</dt><dd>${esc(p.phone)}</dd>` : ''}
      <dt>Registered</dt><dd>${fmt(p.date)}</dd>${p.status === 'verified' ? `<dt>Password</dt><dd>${p.must_change_password ? 'Temporary (not yet changed)' : 'Set by professional'}</dd>` : ''}</dl>
    ${p.status === 'pending' ? `<div id="checks"><label class="check"><input type="checkbox"> Name matches the PRC ID</label><label class="check"><input type="checkbox"> License is valid and active in PRC records</label><label class="check"><input type="checkbox"> Facility affiliation confirmed</label></div>` : ''}
    <div class="form-actions"><button class="btn" data-close>Close</button>${acts}</div>`);
}

function openRegister() {
  const opts = me.professions.map(p => `<option value="${esc(p.value)}">${esc(p.label)}</option>`).join('');
  openModal(`<h2>Register Professional</h2><p class="sub">Adds them to Pending Verification. Their account stays locked until you approve it.</p>
    <form id="regForm" class="form modal-form">
      <label>Full name<input name="full_name" required maxlength="150"></label>
      <label>Username<input name="username" required maxlength="150" autocomplete="off"></label>
      <label>Profession<select name="profession">${opts}</select></label>
      <label>PRC license number<input name="prc_license_number" required inputmode="numeric" pattern="\\d{4,10}" placeholder="e.g. 0123456"></label>
      <label>PRC license expiry<input name="prc_license_expiry" type="date" required></label>
      <label>Email<input name="contact_email" type="email" required></label>
      <label>Contact number<input name="contact_number" type="tel" maxlength="20" placeholder="Optional"></label>
      <label class="full">Facility<input name="facility_name" required maxlength="200"></label>
      <div id="regErrors" class="full"></div>
      <div class="form-actions full"><button type="button" class="btn" data-close>Cancel</button><button class="btn primary">Submit for verification</button></div>
    </form>`);
}

function showTempPassword(p, pw) {
  openModal(`<h2>Temporary password</h2><p class="sub">${esc(p.name)} · username <b>${esc(p.username)}</b></p>
    <div class="temp-pw"><code id="tempPw">${esc(pw)}</code><button class="btn sm" id="copyPw" type="button">Copy</button></div>
    <p class="note">Shown only once. Give it to the professional in person or by phone, not by email or chat. They must change it the first time they sign in to the Muni app.</p>
    <div class="form-actions"><button class="btn primary" data-close>Done</button></div>`, true);
}
async function copyTempPassword() {
  try { await navigator.clipboard.writeText($('#tempPw').textContent); toast('Copied.'); }
  catch { toast('Copy failed. Select the password and copy it manually.'); }
}

function confirmLogout() {
  closeMenus();
  openModal(`<h2>Log out?</h2><p class="sub">You will need to sign in again to manage professionals.</p>
    <div class="form-actions"><button class="btn" data-close>Cancel</button><button class="btn primary" data-act="logout">Logout</button></div>`);
}

async function act(a, id, btn) {
  btn.disabled = true;
  try {
    const data = await api(`professionals/${id}/action/`, { method: 'POST', body: { action: a, checklist: a === 'approve' } });
    await go(current);
    if (data.temporary_password) showTempPassword(data.professional, data.temporary_password);
    else { closeModal(); toast(`${data.professional.name} ${DONE[a]}`); }
  } catch (e) {
    btn.disabled = false;
    if (e.status !== 401) toast(e.message);
  }
}

/* ---------- Events ---------- */
document.addEventListener('click', e => {
  if (e.target.id === 'modal') { if (!$('#modal').dataset.sticky) closeModal(); return; }
  if (!e.target.closest('.user')) $('#userMenu').hidden = true;
  if (e.target.closest('#copyPw')) return copyTempPassword();
  const t = e.target.closest('[data-go],[data-open],[data-act],[data-close],[data-reg],[data-addfac],[data-fac],[data-facdel]');
  if (!t) return;
  if (t.hasAttribute('data-reg')) return openRegister();
  if (t.hasAttribute('data-addfac')) return openFacility(null);
  if (t.dataset.fac) return openFacility(t.dataset.fac);
  if (t.hasAttribute('data-facdel')) return deleteFacility(t);
  if (t.dataset.go) return go(t.dataset.go);
  if (t.dataset.open) return openPro(t.dataset.open);
  if (t.hasAttribute('data-close')) return closeModal();
  if (t.dataset.act === 'logout') return logout();
  if (t.dataset.act) return act(t.dataset.act, t.dataset.id, t);
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
document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  if (!$('#modal').dataset.sticky) closeModal();
  closeMenus();
});

document.addEventListener('input', e => {
  if (e.target.id === 'q' || e.target.id === 'f') {
    const q = $('#q').value.toLowerCase(), f = $('#f').value;
    const list = pros.filter(p => (!f || p.status === f) && (p.name + p.lic).toLowerCase().includes(q));
    $('#tbody').innerHTML = rows(list); $('#n').textContent = list.length;
  }
});
document.addEventListener('change', e => {
  if (e.target.id === 'range') { range = +e.target.value; go('dashboard'); }
  if (e.target.closest('#checks')) {
    $('#approveBtn').disabled = ![...document.querySelectorAll('#checks input')].every(i => i.checked);
  }
});

document.addEventListener('submit', async e => {
  e.preventDefault();
  const f = e.target;

  if (f.id === 'loginForm') {
    const b = f.querySelector('.btn');
    b.classList.add('loading'); b.querySelector('.txt').textContent = 'Signing in…';
    $('#loginError').hidden = true;
    try {
      const data = await api('login/', {
        method: 'POST', auth: false,
        body: { username: f.elements.user.value, password: f.elements.pass.value, remember: f.elements.remember.checked }
      });
      f.reset();
      signedIn(data);
      toast(`Welcome back, ${data.name}.`);
    } catch (err) {
      $('#loginError').textContent = err.message;
      $('#loginError').hidden = false;
    } finally {
      b.classList.remove('loading'); b.querySelector('.txt').textContent = 'Sign in';
    }
  }

  else if (f.id === 'regForm') {
    const btn = f.querySelector('button.primary');
    btn.disabled = true;
    try {
      await api('professionals/', { method: 'POST', body: Object.fromEntries(new FormData(f)) });
      closeModal();
      toast('Registered. Added to Pending Verification.');
      go('pending');
    } catch (err) {
      btn.disabled = false;
      if (err.status !== 401) $('#regErrors').innerHTML = `<p class="form-error">${esc(err.message)}</p>${errorList(err.fields)}`;
    }
  }

  else if (f.id === 'facForm') {
    const btn = f.querySelector('button.primary');
    const body = Object.fromEntries(new FormData(f));
    body.is_verified = f.elements.is_verified.checked;
    body.is_active = f.elements.is_active.checked;
    const id = f.dataset.id;
    btn.disabled = true;
    try {
      await api(id ? `facilities/${id}/` : 'facilities/', { method: 'POST', body });
      closeModal();
      toast(id ? 'Facility updated.' : 'Facility added.');
      go('facilities');
    } catch (err) {
      btn.disabled = false;
      if (err.status !== 401) $('#facErrors').innerHTML = `<p class="form-error">${esc(err.message)}</p>${errorList(err.fields)}`;
    }
  }

  else if (f.id === 'setForm') {
    const btn = f.querySelector('button.primary');
    btn.disabled = true;
    try {
      const data = await api('settings/', { method: 'POST', body: Object.fromEntries(new FormData(f)) });
      me = data;
      $('#userName').textContent = data.name;
      $('#avatar').textContent = data.initials;
      toast('Changes saved.');
      go('settings');
    } catch (err) {
      btn.disabled = false;
      if (err.status !== 401) $('#setErrors').innerHTML = `<p class="form-error">${esc(err.message)}</p>${errorList(err.fields)}`;
    }
  }
});

const syncBurger = () => $('#burger').setAttribute('aria-expanded', mobile() ? $('#app').classList.contains('open') : !$('#app').classList.contains('collapsed'));
window.addEventListener('resize', syncBurger);
syncBurger();
boot();
