import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  dirty = false;

  connect() {
    this.element.addEventListener('input', () => { this.dirty = true; });
    this.element.addEventListener('submit', () => { this.dirty = false; });
    this._onBeforeUnload = (e) => { if (this.dirty) { e.preventDefault(); e.returnValue = ''; } };
    window.addEventListener('beforeunload', this._onBeforeUnload);
  }

  disconnect() { window.removeEventListener('beforeunload', this._onBeforeUnload); }
}
