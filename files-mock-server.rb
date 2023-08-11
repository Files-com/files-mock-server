#!/usr/bin/env ruby

$stderr.reopen $stdout

require 'rubygems'
require 'bundler'
require 'fileutils'
require 'socket'
require 'timeout'

Bundler.require(:default)

require 'active_support'
require 'active_support/core_ext'

$LOAD_PATH.push __dir__

require 'lib/base64_upload'
require 'lib/grape_extensions'

require "app/action_notification_export_api"
require "app/action_notification_export_result_api"
require "app/action_webhook_failure_api"
require "app/api_key_api"
require "app/app_api"
require "app/as2_incoming_message_api"
require "app/as2_outgoing_message_api"
require "app/as2_partner_api"
require "app/as2_station_api"
require "app/automation_api"
require "app/automation_run_api"
require "app/bandwidth_snapshot_api"
require "app/behavior_api"
require "app/bundle_api"
require "app/bundle_download_api"
require "app/bundle_notification_api"
require "app/bundle_recipient_api"
require "app/bundle_registration_api"
require "app/clickwrap_api"
require "app/dns_record_api"
require "app/email_incoming_message_api"
require "app/external_event_api"
require "app/file_api"
require "app/file_comment_api"
require "app/file_comment_reaction_api"
require "app/file_migration_api"
require "app/folder_api"
require "app/form_field_set_api"
require "app/gpg_key_api"
require "app/group_api"
require "app/group_user_api"
require "app/history_api"
require "app/history_export_api"
require "app/history_export_result_api"
require "app/inbox_recipient_api"
require "app/inbox_registration_api"
require "app/inbox_upload_api"
require "app/invoice_api"
require "app/ip_address_api"
require "app/lock_api"
require "app/message_api"
require "app/message_comment_api"
require "app/message_comment_reaction_api"
require "app/message_reaction_api"
require "app/notification_api"
require "app/payment_api"
require "app/permission_api"
require "app/priority_api"
require "app/project_api"
require "app/public_key_api"
require "app/remote_bandwidth_snapshot_api"
require "app/remote_server_api"
require "app/request_api"
require "app/session_api"
require "app/settings_change_api"
require "app/sftp_host_key_api"
require "app/share_group_api"
require "app/site_api"
require "app/snapshot_api"
require "app/sso_strategy_api"
require "app/style_api"
require "app/usage_daily_snapshot_api"
require "app/usage_snapshot_api"
require "app/user_api"
require "app/user_cipher_use_api"
require "app/user_request_api"
require "app/webhook_test_api"

class FilesMockServer::API < Grape::API
  mount FilesMockServer::ActionNotificationExportAPI
  mount FilesMockServer::ActionNotificationExportResultAPI
  mount FilesMockServer::ActionWebhookFailureAPI
  mount FilesMockServer::ApiKeyAPI
  mount FilesMockServer::AppAPI
  mount FilesMockServer::As2IncomingMessageAPI
  mount FilesMockServer::As2OutgoingMessageAPI
  mount FilesMockServer::As2PartnerAPI
  mount FilesMockServer::As2StationAPI
  mount FilesMockServer::AutomationAPI
  mount FilesMockServer::AutomationRunAPI
  mount FilesMockServer::BandwidthSnapshotAPI
  mount FilesMockServer::BehaviorAPI
  mount FilesMockServer::BundleAPI
  mount FilesMockServer::BundleDownloadAPI
  mount FilesMockServer::BundleNotificationAPI
  mount FilesMockServer::BundleRecipientAPI
  mount FilesMockServer::BundleRegistrationAPI
  mount FilesMockServer::ClickwrapAPI
  mount FilesMockServer::DnsRecordAPI
  mount FilesMockServer::EmailIncomingMessageAPI
  mount FilesMockServer::ExternalEventAPI
  mount FilesMockServer::FileAPI
  mount FilesMockServer::FileCommentAPI
  mount FilesMockServer::FileCommentReactionAPI
  mount FilesMockServer::FileMigrationAPI
  mount FilesMockServer::FolderAPI
  mount FilesMockServer::FormFieldSetAPI
  mount FilesMockServer::GpgKeyAPI
  mount FilesMockServer::GroupAPI
  mount FilesMockServer::GroupUserAPI
  mount FilesMockServer::HistoryAPI
  mount FilesMockServer::HistoryExportAPI
  mount FilesMockServer::HistoryExportResultAPI
  mount FilesMockServer::InboxRecipientAPI
  mount FilesMockServer::InboxRegistrationAPI
  mount FilesMockServer::InboxUploadAPI
  mount FilesMockServer::InvoiceAPI
  mount FilesMockServer::IpAddressAPI
  mount FilesMockServer::LockAPI
  mount FilesMockServer::MessageAPI
  mount FilesMockServer::MessageCommentAPI
  mount FilesMockServer::MessageCommentReactionAPI
  mount FilesMockServer::MessageReactionAPI
  mount FilesMockServer::NotificationAPI
  mount FilesMockServer::PaymentAPI
  mount FilesMockServer::PermissionAPI
  mount FilesMockServer::PriorityAPI
  mount FilesMockServer::ProjectAPI
  mount FilesMockServer::PublicKeyAPI
  mount FilesMockServer::RemoteBandwidthSnapshotAPI
  mount FilesMockServer::RemoteServerAPI
  mount FilesMockServer::RequestAPI
  mount FilesMockServer::SessionAPI
  mount FilesMockServer::SettingsChangeAPI
  mount FilesMockServer::SftpHostKeyAPI
  mount FilesMockServer::ShareGroupAPI
  mount FilesMockServer::SiteAPI
  mount FilesMockServer::SnapshotAPI
  mount FilesMockServer::SsoStrategyAPI
  mount FilesMockServer::StyleAPI
  mount FilesMockServer::UsageDailySnapshotAPI
  mount FilesMockServer::UsageSnapshotAPI
  mount FilesMockServer::UserAPI
  mount FilesMockServer::UserCipherUseAPI
  mount FilesMockServer::UserRequestAPI
  mount FilesMockServer::WebhookTestAPI
end
