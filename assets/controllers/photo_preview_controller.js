import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'preview'];

  previewLocal() {
    const file = this.inputTarget.files[0];

    if (!file) {
      this.renderText('JPG, PNG o WEBP · máximo 2 MB', 'sf-photo__hint');
      return;
    }

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      this.renderText('Usa una imagen JPG, PNG o WEBP.', 'error');
      this.inputTarget.value = '';
      return;
    }

    if (file.size > 2 * 1024 * 1024) {
      this.renderText('La imagen supera el máximo de 2 MB.', 'error');
      this.inputTarget.value = '';
      return;
    }

    const url = URL.createObjectURL(file);
    const image = document.createElement('img');
    image.src = url;
    image.alt = 'Vista previa de fotografía';
    image.className = 'sf-photo__preview';

    const filename = document.createElement('span');
    filename.className = 'sf-photo__filename';
    filename.textContent = file.name;

    this.previewTarget.replaceChildren(image, filename);
  }

  renderText(message, className) {
    const element = document.createElement(className === 'error' ? 'p' : 'span');
    element.className = className;
    element.textContent = message;
    this.previewTarget.replaceChildren(element);
  }
}
