import { Controller } from '@hotwired/stimulus';

// Autocompletado accesible (combobox + listbox) para filtros GET.
// Options: [{value, label, hint}] en data-combobox-options-value.
// Al elegir una opción escribe el valor en el input hidden name=... del form.
export default class extends Controller {
  static targets = ['input', 'hidden', 'list', 'clear'];
  static values = { options: Array };

  connect() {
    this.index = -1;
    this.filtered = this.optionsValue;
    this.render();
    this.syncFromHidden();
    this.element.closest('form')?.addEventListener('reset', () => {
      window.setTimeout(() => this.syncFromHidden(), 0);
    });
    this.inputTarget.addEventListener('keydown', (e) => this.onKeydown(e));
    this.inputTarget.addEventListener('focus', () => this.open());
    this.inputTarget.addEventListener('input', () => this.onInput());
    this.listTarget.addEventListener('mousedown', (e) => {
      const item = e.target.closest('[role="option"]');
      if (item) { e.preventDefault(); this.select(parseInt(item.dataset.index, 10)); }
    });
    document.addEventListener('mousedown', (e) => {
      if (!this.element.contains(e.target)) this.close();
    });
  }

  disconnect() { this.close(); }

  norm(s) {
    return (s || '').toString().normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  }

  syncFromHidden() {
    const value = this.hiddenTarget.value;
    const opt = this.optionsValue.find((o) => String(o.value) === String(value));
    this.inputTarget.value = opt ? opt.label : '';
    this.hiddenTarget.value = value;
    this.refreshClear();
  }

  onInput() {
    const needle = this.norm(this.inputTarget.value);
    this.hiddenTarget.value = '';
    this.refreshClear();
    this.filtered = needle === ''
      ? this.optionsValue
      : this.optionsValue.filter((o) => this.norm(o.label).includes(needle) || this.norm(o.hint || '').includes(needle));
    this.index = -1;
    this.render();
    this.open();
  }

  onKeydown(e) {
    if (e.key === 'ArrowDown') { e.preventDefault(); this.open(); this.move(1); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); this.open(); this.move(-1); }
    else if (e.key === 'Enter') {
      if (this.element.classList.contains('is-open') && this.index >= 0) { e.preventDefault(); this.select(this.index); }
    } else if (e.key === 'Escape') { this.close(); }
  }

  move(step) {
    if (!this.element.classList.contains('is-open')) return;
    const max = this.filtered.length - 1;
    if (max < 0) return;
    this.index = this.index < 0 ? (step > 0 ? 0 : max) : Math.min(max, Math.max(0, this.index + step));
    this.highlight();
  }

  highlight() {
    const items = this.listTarget.querySelectorAll('[role="option"]');
    items.forEach((el, i) => {
      const active = i === this.index;
      el.classList.toggle('is-active', active);
      if (active) {
        el.setAttribute('aria-selected', 'true');
        this.inputTarget.setAttribute('aria-activedescendant', el.id);
        el.scrollIntoView({ block: 'nearest' });
      } else {
        el.removeAttribute('aria-selected');
      }
    });
  }

  select(i) {
    const opt = this.filtered[i];
    if (!opt) return;
    this.hiddenTarget.value = opt.value;
    this.inputTarget.value = opt.label;
    this.refreshClear();
    this.close();
    this.element.dispatchEvent(new CustomEvent('combobox:change', { detail: { value: opt.value, label: opt.label }, bubbles: true }));
  }

  clear(e) {
    e.preventDefault();
    this.hiddenTarget.value = '';
    this.inputTarget.value = '';
    this.refreshClear();
    this.filtered = this.optionsValue;
    this.render();
    this.inputTarget.focus();
    this.element.dispatchEvent(new CustomEvent('combobox:change', { detail: { value: '' }, bubbles: true }));
  }

  refreshClear() {
    if (this.hasClearTarget) this.clearTarget.hidden = this.hiddenTarget.value === '';
  }

  open() {
    this.element.classList.add('is-open');
    this.listTarget.hidden = false;
    this.inputTarget.setAttribute('aria-expanded', 'true');
    this.highlight();
  }

  close() {
    this.element.classList.remove('is-open');
    this.listTarget.hidden = true;
    this.inputTarget.setAttribute('aria-expanded', 'false');
    this.index = -1;
    this.syncFromHidden();
  }

  render() {
    this.listTarget.replaceChildren();
    if (this.filtered.length === 0) {
      const li = document.createElement('li');
      li.className = 'combobox__empty';
      li.setAttribute('role', 'presentation');
      li.textContent = 'Sin coincidencias';
      this.listTarget.appendChild(li);
      return;
    }
    const frag = document.createDocumentFragment();
    this.filtered.slice(0, 80).forEach((o, i) => {
      const li = document.createElement('li');
      li.id = `${this.inputTarget.id}-opt-${i}`;
      li.setAttribute('role', 'option');
      li.dataset.index = String(i);
      li.className = 'combobox__opt';
      const label = document.createElement('span');
      label.textContent = o.label;
      li.appendChild(label);
      if (o.hint) {
        const hint = document.createElement('span');
        hint.className = 'combobox__hint';
        hint.textContent = o.hint;
        li.appendChild(hint);
      }
      frag.appendChild(li);
    });
    this.listTarget.appendChild(frag);
  }
}
