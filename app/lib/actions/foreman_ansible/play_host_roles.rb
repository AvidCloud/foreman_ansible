module Actions
  module ForemanAnsible
    # Action that initiates the playbook run for roles assigned to
    # the host. It does that either locally or via a proxy when available.
    class PlayHostRoles < PlayRoles
      def plan(host, proxy_selector = ::ForemanAnsible::ProxySelector.new)
        input[:host] = { :id => host.id, :name => host.fqdn }
        proxy = proxy_selector.determine_proxy(host)
        inventory_creator = ::ForemanAnsible::InventoryCreator.new([host])
        role_names = host.all_ansible_roles.map(&:name)
        playbook_creator = ::ForemanAnsible::PlaybookCreator.new(role_names)
        plan_delegated_action(proxy, ::ForemanAnsibleCore::Actions::RunPlaybook,
                              :inventory => inventory_creator.to_hash.to_json,
                              :playbook => playbook_creator.roles_playbook)
        plan_self
      end

      def humanized_input
        _('on host %{name}') % { :name => input.fetch(:host, {})[:name] }
      end

      def humanized_name
        _('Play Ansible roles')
      end
    end
  end
end
