function show_ad_hoc_role_modal(all_ansible_roles) {
  var modal_window = $('#adHocRoleModal');

  modal_window.find('.modal-title').text(__('Ad Hoc Ansible Role Execution'));
  modal_window.modal({'show': true});

  modal_window.find('a[rel="popover-modal"]').popover();
  activate_select2(modal_window);
}

function close_ad_hoc_role_modal() {
  var modal_window = $('#adHocRoleModal');

  modal_window.modal('hide');
}
