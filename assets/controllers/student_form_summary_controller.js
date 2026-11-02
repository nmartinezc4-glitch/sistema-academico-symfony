import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'firstNames', 'lastNames', 'birthDate', 'address',
    'career', 'curriculum', 'programStart', 'programStatus', 'generatedCode',
    'summaryName', 'summaryCode', 'summaryBirth', 'summaryAddress',
    'summaryCareer', 'summaryCurriculum', 'summaryStart', 'summaryStatus'
  ];

  static values = {
    fixedCode: String,
  };

  connect() {
    this.update();
  }

  update() {
    const firstNames = this.hasFirstNamesTarget ? this.firstNamesTarget.value.trim() : '';
    const lastNames = this.hasLastNamesTarget ? this.lastNamesTarget.value.trim() : '';
    const fullName = [firstNames, lastNames].filter(Boolean).join(' ');
    const code = this.hasFixedCodeValue ? this.fixedCodeValue : this.previewCode();

    if (this.hasGeneratedCodeTarget) this.generatedCodeTarget.textContent = code;
    if (this.hasSummaryNameTarget) this.summaryNameTarget.textContent = fullName || 'Nombre pendiente';
    if (this.hasSummaryCodeTarget) this.summaryCodeTarget.textContent = code;
    if (this.hasSummaryBirthTarget) this.summaryBirthTarget.textContent = this.hasBirthDateTarget && this.birthDateTarget.value ? this.formatDate(this.birthDateTarget.value) : 'Fecha pendiente';
    if (this.hasSummaryAddressTarget) this.summaryAddressTarget.textContent = this.hasAddressTarget && this.addressTarget.value.trim() ? this.addressTarget.value.trim() : 'No registrada';
    if (this.hasSummaryCareerTarget && this.hasCareerTarget) this.summaryCareerTarget.textContent = this.selectedLabel(this.careerTarget, 'Pendiente');
    if (this.hasSummaryCurriculumTarget && this.hasCurriculumTarget) this.summaryCurriculumTarget.textContent = this.selectedLabel(this.curriculumTarget, 'Pendiente');
    if (this.hasSummaryStartTarget) this.summaryStartTarget.textContent = this.hasProgramStartTarget && this.programStartTarget.value ? this.formatDate(this.programStartTarget.value) : 'Pendiente';

    if (this.hasSummaryStatusTarget) {
      const status = this.hasProgramStatusTarget && this.programStatusTarget.value
        ? this.programStatusTarget.value
        : 'ACTIVO';
      this.summaryStatusTarget.textContent = status;
      this.summaryStatusTarget.classList.remove('badge--success', 'badge--info', 'badge--warning', 'badge--danger', 'badge--neutral');
      this.summaryStatusTarget.classList.add(this.statusTone(status));
    }
  }

  previewCode() {
    if (!this.hasProgramStartTarget || !this.programStartTarget.value) {
      return 'STU-AAAA-####';
    }

    const year = this.programStartTarget.value.slice(0, 4);
    return /^\d{4}$/.test(year) ? `STU-${year}-####` : 'STU-AAAA-####';
  }

  statusTone(status) {
    if (status === 'ACTIVO') return 'badge--success';
    if (status === 'FINALIZADO') return 'badge--info';
    if (status === 'RETIRADO') return 'badge--danger';
    return 'badge--neutral';
  }

  selectedLabel(select, fallback) {
    const option = select.selectedOptions?.[0];
    if (!option || !option.value) return fallback;
    return option.textContent.trim();
  }

  formatDate(value) {
    const parts = value.split('-');
    if (parts.length !== 3) return value;
    return `${parts[2]}/${parts[1]}/${parts[0]}`;
  }
}
