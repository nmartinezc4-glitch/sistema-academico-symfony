import { Controller } from '@hotwired/stimulus';

// Tabs solo-visuales cuando no son navegación real.
export default class extends Controller {
  static targets = ['tab', 'panel'];

  select(event) {
    event.preventDefault();
    const index = this.tabTargets.indexOf(event.currentTarget);
    this.tabTargets.forEach((t, i) => t.setAttribute('aria-selected', i === index));
    this.panelTargets.forEach((p, i) => { p.hidden = i !== index; });
  }
}
