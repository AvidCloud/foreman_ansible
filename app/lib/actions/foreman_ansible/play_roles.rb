module Actions
  module ForemanAnsible
    # The base class for similar actions that execute Ansible roles.
    class PlayRoles < Actions::EntryAction
      include ::Actions::Helpers::WithContinuousOutput
      include ::Actions::Helpers::WithDelegatedAction

      def finalize
        return unless delegated_output[:exit_status].to_s != '0'
        error! _('Playbook execution failed')
      end

      def rescue_strategy
        ::Dynflow::Action::Rescue::Fail
      end

      def humanized_output
        continuous_output.humanize
      end

      def continuous_output_providers
        super << self
      end

      def fill_continuous_output(continuous_output)
        delegated_output.fetch('result', []).each do |raw_output|
          continuous_output.add_raw_output(raw_output)
        end
      rescue => e
        continuous_output.add_exception(_('Error loading data from proxy'), e)
      end
    end
  end
end
