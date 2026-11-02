import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['career', 'curriculum', 'programStart', 'validityHint'];
  static values = { curricula: Array, emptyLabel: String };

  connect() {
    this.refresh();
  }

  refresh() {
    const careerId = this.careerTarget.value;
    const select = this.curriculumTarget;
    const current = select.value;
    const startDate = this.hasProgramStartTarget ? this.programStartTarget.value : '';

    const emptyLabel = this.hasEmptyLabelValue ? this.emptyLabelValue : 'Seleccione…';
    select.replaceChildren(new Option(emptyLabel, ''));

    const candidates = (this.curriculaValue || [])
      .filter(c => !careerId || String(c.careerId) === String(careerId))
      .filter(c => this.isValidForDate(c, startDate));

    candidates.forEach(c => {
      const option = document.createElement('option');
      option.value = c.id;
      option.textContent = `${c.code} · ${c.name}`;
      if (String(current) === String(c.id)) option.selected = true;
      select.appendChild(option);
    });

    if (this.hasValidityHintTarget) {
      if (!careerId) {
        this.validityHintTarget.textContent = 'Selecciona primero una carrera.';
      } else if (!startDate) {
        this.validityHintTarget.textContent = 'Indica la fecha de ingreso para validar la vigencia del pensum.';
      } else if (candidates.length === 0) {
        this.validityHintTarget.textContent = 'No hay pensums activos y vigentes para esa carrera en la fecha de ingreso seleccionada.';
      } else {
        this.validityHintTarget.textContent = 'Solo se muestran pensums vigentes para la fecha de ingreso.';
      }
    }

    if (![...select.options].some(option => option.value === current)) {
      select.value = '';
    }

    select.dispatchEvent(new Event('change', { bubbles: true }));
  }

  isValidForDate(curriculum, startDate) {
    if (!startDate) return true;

    const validFrom = curriculum.validFrom || curriculum.pen_vigente_desde || null;
    const validUntil = curriculum.validUntil || curriculum.pen_vigente_hasta || null;

    if (validFrom && startDate < String(validFrom).slice(0, 10)) return false;
    if (validUntil && startDate > String(validUntil).slice(0, 10)) return false;

    return true;
  }
}
