import { startStimulusApp } from '@symfony/stimulus-bundle';
import SidebarController from './controllers/sidebar_controller.js';
import TabsController from './controllers/tabs_controller.js';
import DependentSelectController from './controllers/dependent_select_controller.js';
import PhotoPreviewController from './controllers/photo_preview_controller.js';
import DirtyFormController from './controllers/dirty_form_controller.js';
import ComboboxController from './controllers/combobox_controller.js';
import StudentRangeController from './controllers/student_range_controller.js';
import StudentFormSummaryController from './controllers/student_form_summary_controller.js';

const app = startStimulusApp();
app.register('sidebar', SidebarController);
app.register('tabs', TabsController);
app.register('dependent-select', DependentSelectController);
app.register('photo-preview', PhotoPreviewController);
app.register('dirty-form', DirtyFormController);
app.register('combobox', ComboboxController);

app.register('student-range', StudentRangeController);

app.register('student-form-summary', StudentFormSummaryController);
