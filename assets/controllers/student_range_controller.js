import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['min', 'max', 'output'];

  connect() {
    this.update();
  }

  update(event) {
    let min = Number(this.minTarget.value);
    let max = Number(this.maxTarget.value);

    if (min > max) {
      if (event?.target === this.minTarget) {
        max = min;
        this.maxTarget.value = String(max);
      } else {
        min = max;
        this.minTarget.value = String(min);
      }
    }

    this.element.style.setProperty('--range-min', `${min}%`);
    this.element.style.setProperty('--range-max', `${max}%`);
    this.outputTarget.textContent = `${min} % – ${max} %`;
  }
}
