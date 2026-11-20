document.documentElement.classList.add('js');

const normalizePath = (path) => {
  const clean = path.replace(/\/index\.html$/, '/').replace(/\.html$/, '').replace(/\/$/, '');
  return clean || '/';
};

const currentPath = normalizePath(window.location.pathname);

document.querySelectorAll('a[href]').forEach((link) => {
  const url = new URL(link.href, window.location.href);
  if (url.origin === window.location.origin && normalizePath(url.pathname) === currentPath) {
    link.setAttribute('aria-current', 'page');
  }
});

const navToggle = document.querySelector('[data-nav-toggle]');
const primaryNav = document.querySelector('[data-primary-nav]');

const closeNavigation = () => {
  if (!navToggle || !primaryNav) return;
  navToggle.setAttribute('aria-expanded', 'false');
  primaryNav.classList.remove('is-open');
};

navToggle?.addEventListener('click', () => {
  const open = navToggle.getAttribute('aria-expanded') === 'true';
  navToggle.setAttribute('aria-expanded', String(!open));
  primaryNav?.classList.toggle('is-open', !open);
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    closeNavigation();
    document.querySelectorAll('.primary-nav details[open]').forEach((menu) => menu.removeAttribute('open'));
  }
});

document.addEventListener('click', (event) => {
  const header = document.querySelector('[data-site-header]');
  if (header && !header.contains(event.target)) closeNavigation();
});

primaryNav?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => closeNavigation());
});

const docsToggle = document.querySelector('[data-docs-toggle]');
const docsPanel = document.querySelector('[data-docs-panel]');

docsToggle?.addEventListener('click', () => {
  const open = docsToggle.getAttribute('aria-expanded') === 'true';
  docsToggle.setAttribute('aria-expanded', String(!open));
  docsPanel?.classList.toggle('is-open', !open);
  const indicator = docsToggle.querySelector('[aria-hidden="true"]');
  if (indicator) indicator.textContent = open ? '+' : '−';
});

const docsFilter = document.querySelector('[data-docs-filter]');
docsFilter?.addEventListener('input', () => {
  const query = docsFilter.value.trim().toLocaleLowerCase();
  document.querySelectorAll('[data-docs-section]').forEach((section) => {
    let visibleItems = 0;
    section.querySelectorAll('[data-docs-item]').forEach((item) => {
      const match = item.textContent.toLocaleLowerCase().includes(query);
      item.hidden = !match;
      if (match) visibleItems += 1;
    });
    section.hidden = visibleItems === 0;
  });
});

document.querySelectorAll('.prose table').forEach((table) => {
  if (table.parentElement?.classList.contains('table-scroll')) return;
  const wrapper = document.createElement('div');
  wrapper.className = 'table-scroll';
  wrapper.tabIndex = 0;
  wrapper.setAttribute('role', 'region');
  wrapper.setAttribute('aria-label', 'Scrollable table');
  table.parentNode.insertBefore(wrapper, table);
  wrapper.appendChild(table);
});
