module Actions
  module ForemanAnsible
    # Actions that initiaztes the playbook run for roles assigned to
    # the host. It doest that either locally or via a proxy when available.
    class PlayHostRole < PlayRoles
      def plan(host, ansible_role, proxy_selector = ::ForemanAnsible::ProxySelector.new)
        input[:host] = { :id => host.id, :name => host.fqdn }
        proxy = proxy_selector.determine_proxy(host)
        inventory_creator = ::ForemanAnsible::InventoryCreator.new([host])
        playbook_creator = ::ForemanAnsible::PlaybookCreator.new([ansible_role.name])
        plan_delegated_action(proxy, ::ForemanAnsibleCore::Actions::RunPlaybook,
                              :inventory => inventory_creator.to_hash.to_json,
                              :playbook => playbook_creator.roles_playbook)
        plan_self
      end

      def humanized_input
        _('on host %{name}') % { :name => input.fetch(:host, {})[:name] }
      end

      def humanized_name
        _('Play ad hoc Ansible role')
      end
    end
  end
end
