module Actions
  module ForemanAnsible
    module Concerns
      # Common behaviour for Ansible progress polling
      module PollingCommon
        extend ActiveSupport::Concern

        DEFAULT_POLLING_FILE = 'status_report.json'.freeze

        included do
          def poll_intervals
            [5]
          end

          def done?
            !File.directory?(input[:working_dir])
          end

          def invoke_external_task; end

          def poll_external_task
            progress = empty_progress
            if done?
              progress[:ansible_progress] = 100.0
            else
              begin
                file_path = File.join(input[:working_dir], DEFAULT_POLLING_FILE)
                return error_message unless File.file?(file_path)
                content = JSON.parse(File.read(file_path))
                progress[:ansible_task_name] = content['task_name']
                progress[:ansible_progress] = content['progress']
                progress[:ansible_task_amount] = content['amount']
                progress[:ansible_task_count] = content['count']
              rescue
                return error_message
              end
            end
            progress
          end
        end

        def error_message
          { :error => _('Polling file not available') }
        end

        def empty_progress
          {
            :ansible_task_name => '',
            :ansible_progress => 0.0,
            :ansible_task_amount => 0,
            :ansible_task_count => 0
          }
        end
      end
    end
  end
end
