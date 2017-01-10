module Actions
  module ForemanAnsible
    # Action that initiates the playbook run for roles assigned to
    # the hostgroup. It does that either locally or via a proxy when available.
    class PlayHostgroupRoles < PlayRoles
      def plan(hostgroup, proxy_selector = ::ForemanAnsible::ProxySelector.new)
        if hostgroup.hosts.empty?
          raise ::Foreman::Exception.new(N_('host group is empty'))
        end
        input[:hostgroup] = { :id => hostgroup.id, :name => hostgroup.name }
        proxy = proxy_selector.determine_proxy(hostgroup.hosts[0])
        inventory_creator = ::ForemanAnsible::InventoryCreator.new(hostgroup.hosts)
        role_names = []
        hostgroup.hostgroup_ansible_roles.each do |ansible_role|
          role_names.append(ansible_role.ansible_role_name)
        end
        playbook_creator = ::ForemanAnsible::PlaybookCreator.new(role_names)
        plan_delegated_action(
          proxy,
          ::ForemanAnsibleCore::Actions::RunPlaybook,
          :inventory => inventory_creator.to_hash.to_json,
          :playbook => playbook_creator.roles_playbook
        )
        plan_self
      end

      def humanized_input
        _('on host group %{name}') %
          { :name => input.fetch(:hostgroup, {})[:name] }
      end

      def humanized_name
        _('Play Ansible roles')
      end
    end
  end
end
