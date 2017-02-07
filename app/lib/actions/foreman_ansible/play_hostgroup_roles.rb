module Actions
  module ForemanAnsible
    # Action that initiates the playbook run for roles assigned to
    # the hostgroup. It does that either locally or via a proxy when available.
    class PlayHostgroupRoles < Actions::EntryAction
      include ::Actions::Helpers::WithContinuousOutput
      include ::Actions::Helpers::WithDelegatedAction
      include Helpers::PlayRolesDescription
      include Helpers::HostCommon

      def plan(hostgroup, proxy_selector = ::ForemanAnsible::ProxySelector.new,
               options = {})
        proxy = find_hostgroup_and_proxy(hostgroup, proxy_selector)
        inventory_creator = ::ForemanAnsible::
          InventoryCreator.new(gather_nested_hosts(hostgroup))
        playbook_creator = ::ForemanAnsible::
          PlaybookCreator.new(hostgroup_ansible_roles(hostgroup))
        plan_delegated_action(proxy, ::ForemanAnsibleCore::Actions::RunPlaybook,
                              :inventory => inventory_creator.to_hash.to_json,
                              :playbook => playbook_creator.roles_playbook,
                              :options => find_options.merge(options))
        plan_self
      end

      def humanized_input
        _('on host group %{name} through proxy %{proxy}') % {
          :name => input.fetch(:hostgroup, {})[:name],
          :proxy => running_proxy_name
        }
      end

      private

      def hostgroup_ansible_roles(hostgroup)
        role_names = []
        hostgroup.all_ansible_roles.each do |ansible_role|
          role_names.append(ansible_role.name)
        end
        role_names
      end

      def gather_nested_hosts(hostgroup)
        hosts = hostgroup.hosts
        hostgroup.children.each do |child|
          hosts += gather_nested_hosts(child)
        end
        hosts
      end

      def find_hostgroup_and_proxy(hostgroup, proxy_selector)
        hosts = gather_nested_hosts(hostgroup)
        if hosts.empty?
          raise ::Foreman::Exception.new(N_('host group is empty'))
        end

        proxy = proxy_selector.determine_proxy(hosts[0])
        input[:hostgroup] = { :id => hostgroup.id,
                              :name => hostgroup.name,
                              :proxy_used => proxy.try(:name) ||
                                             :not_defined }
        proxy
      end
    end
  end
end
