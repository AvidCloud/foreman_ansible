# UI controller for ansible roles
class AnsibleRolesController < ::ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  include ForemanTasks::Triggers

  before_action :find_resource, :only => [:destroy]
  before_action :find_proxy, :only => [:import]
  before_action :create_importer, :only => [:import, :confirm_import]

  def index
    @ansible_roles = resource_base.search_for(params[:search],
                                              :order => params[:order]).
                     paginate(:page => params[:page],
                              :per_page => params[:per_page])
  end

  def destroy
    if @ansible_role.destroy
      process_success
    else
      process_error
    end
  end

  def import
    changed = @importer.import!
    if changed.values.all?(&:empty?)
      notice no_changed_roles_message
      redirect_to ansible_roles_path
    else
      render :locals => { :changed => changed }
    end
  end

  def confirm_import
    @importer.finish_import(params[:changed])
    notice _('Import of roles successfully finished.')
    redirect_to ansible_roles_path
  end

  def play_ad_hoc_role_on_host
    params[:id] = params[:ansible_role][:id]
    @host = Host.find(params[:host_id])
    find_resource
    task = async_task(::Actions::ForemanAnsible::PlayHostRole, @host, @ansible_role)
    redirect_to task
  rescue Foreman::Exception => e
    error e.message
    redirect_to host_path(@host)
  end

  private

  def action_permission
    case params[:action]
    when 'play_ad_hoc_role_on_host'
      :view
    else
      super
    end
  end

  def find_proxy
    return nil unless params[:proxy]
    @proxy = SmartProxy.authorized(:view_smart_proxies).find(params[:proxy])
  end

  def create_importer
    @importer = ForemanAnsible::UiRolesImporter.new(@proxy)
  end

  def no_changed_roles_message
    return _('No changes in roles detected.') unless @proxy.present?
    _('No changes in roles detected on %s.') % @proxy.name
  end
end
