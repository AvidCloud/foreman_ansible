module Actions
  module ForemanAnsible
    # Action that initiates the playbook run for roles assigned to
    # the hostgroup. It does that either locally or via a proxy when available.
    class PlayHostgroupRoles < Actions::EntryAction
      include ::Actions::Helpers::WithContinuousOutput
      include ::Actions::Helpers::WithDelegatedAction
      include Helpers::PlayRolesDescription
      include Helpers::HostCommon
      include Dynflow::Action::Polling

      def plan(hostgroup, proxy_selector = ::ForemanAnsible::ProxySelector.new,
               options = {})
        proxy = find_hostgroup_and_proxy(hostgroup, proxy_selector)
        inventory_creator = ::ForemanAnsible::
          InventoryCreator.new(hostgroup.hosts)
        playbook_creator = ::ForemanAnsible::
          PlaybookCreator.new(hostgroup_ansible_roles(hostgroup))
        input[:working_dir] = Dir.mktmpdir
        options[:working_dir] = input[:working_dir]
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

      def poll_intervals
        [5]
      end

      def done?
        !File.directory?(input[:working_dir])
      end

      def invoke_external_task
      end

      def poll_external_task
        return_value = {
          :ansible_task_name => '',
          :ansible_progress => 0.0,
          :ansible_task_amount => 0,
          :ansible_task_count => 0
        }

        if done?
          return_value = {
            :ansible_progress => 100.0,
          }
        else
          begin
            file_path = File.join(input[:working_dir], 'status_report.json')
            return {:error => 'status_report not available'} if !File.file?(file_path)
            content = JSON.parse(File.read(file_path))
            return_value[:ansible_task_name] = content['task_name']
            return_value[:ansible_progress] = content['progress']
            return_value[:ansible_task_amount] = content['amount']
            return_value[:ansible_task_count] = content['count']
          rescue
          end
        end

        return_value
      end

      private

      def hostgroup_ansible_roles(hostgroup)
        role_names = []
        hostgroup.hostgroup_ansible_roles.each do |ansible_role|
          role_names.append(ansible_role.ansible_role_name)
        end
        role_names
      end

      def hostgroup_contains_hosts(hostgroup)
        return unless hostgroup.hosts.empty?
        raise ::Foreman::Exception.new(N_('host group is empty'))
      end

      def find_hostgroup_and_proxy(hostgroup, proxy_selector)
        hostgroup_contains_hosts(hostgroup)
        proxy = proxy_selector.determine_proxy(hostgroup.hosts[0])
        input[:hostgroup] = { :id => hostgroup.id,
                              :name => hostgroup.name,
                              :proxy_used => proxy.try(:name) || :not_defined }
        proxy
      end
    end
  end
end
