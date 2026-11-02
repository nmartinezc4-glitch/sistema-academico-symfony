import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { open: Boolean };

  toggle() {
    this.openValue = !this.openValue;
    this.element.dataset.open = this.openValue;
    document.querySelector('[data-action="sidebar#toggle"]')?.setAttribute('aria-expanded', this.openValue);
  }

  connect() {
    this.element.dataset.open = 'false';
    this._onKey = (e) => { if (e.key === 'Escape' && this.openValue) this.toggle(); };
    document.addEventListener('keydown', this._onKey);
  }

  disconnect() {
    document.removeEventListener('keydown', this._onKey);
  }
}
