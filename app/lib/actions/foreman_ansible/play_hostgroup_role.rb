module Actions
  module ForemanAnsible
    # Action that initiates the playbook run for an Ansible role of a
    # hostgroup. It does that either locally or via a proxy when available.
    class PlayHostgroupRole < PlayRoles
      def plan(hostgroup, ansible_role, proxy_selector = ::ForemanAnsible::ProxySelector.new)
        if hostgroup.hosts.empty?
          raise ::Foreman::Exception.new(N_('host group is empty'))
        end
        input[:hostgroup] = { :id => hostgroup.id, :name => hostgroup.name }
        proxy = proxy_selector.determine_proxy(hostgroup.hosts[0])
        inventory_creator = ::ForemanAnsible::InventoryCreator.new(hostgroup.hosts)
        playbook_creator = ::ForemanAnsible::PlaybookCreator.new([ansible_role.name])
        plan_delegated_action(proxy, ::ForemanAnsibleCore::Actions::RunPlaybook,
                              :inventory => inventory_creator.to_hash.to_json,
                              :playbook => playbook_creator.roles_playbook)
        plan_self
      end

      def humanized_input
        _('on host group %{name}') %
          { :name => input.fetch(:hostgroup, {})[:name] }
      end

      def humanized_name
        _('Play ad hoc Ansible role')
      end
    end
  end
end
