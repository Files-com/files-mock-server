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

require "app/api_key_api"
require "app/as2_key_api"
require "app/automation_api"
require "app/behavior_api"
require "app/bundle_api"
require "app/bundle_download_api"
require "app/clickwrap_api"
require "app/dns_record_api"
require "app/file_api"
require "app/file_action_api"
require "app/file_comment_api"
require "app/file_comment_reaction_api"
require "app/folder_api"
require "app/group_api"
require "app/group_user_api"
require "app/history_api"
require "app/history_export_api"
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
require "app/project_api"
require "app/public_key_api"
require "app/remote_server_api"
require "app/request_api"
require "app/session_api"
require "app/site_api"
require "app/sso_strategy_api"
require "app/style_api"
require "app/usage_daily_snapshot_api"
require "app/usage_snapshot_api"
require "app/user_api"
require "app/user_cipher_use_api"
require "app/user_request_api"

class FilesMockServer::API < Grape::API
  mount FilesMockServer::ApiKeyAPI
  mount FilesMockServer::As2KeyAPI
  mount FilesMockServer::AutomationAPI
  mount FilesMockServer::BehaviorAPI
  mount FilesMockServer::BundleAPI
  mount FilesMockServer::BundleDownloadAPI
  mount FilesMockServer::ClickwrapAPI
  mount FilesMockServer::DnsRecordAPI
  mount FilesMockServer::FileAPI
  mount FilesMockServer::FileActionAPI
  mount FilesMockServer::FileCommentAPI
  mount FilesMockServer::FileCommentReactionAPI
  mount FilesMockServer::FolderAPI
  mount FilesMockServer::GroupAPI
  mount FilesMockServer::GroupUserAPI
  mount FilesMockServer::HistoryAPI
  mount FilesMockServer::HistoryExportAPI
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
  mount FilesMockServer::ProjectAPI
  mount FilesMockServer::PublicKeyAPI
  mount FilesMockServer::RemoteServerAPI
  mount FilesMockServer::RequestAPI
  mount FilesMockServer::SessionAPI
  mount FilesMockServer::SiteAPI
  mount FilesMockServer::SsoStrategyAPI
  mount FilesMockServer::StyleAPI
  mount FilesMockServer::UsageDailySnapshotAPI
  mount FilesMockServer::UsageSnapshotAPI
  mount FilesMockServer::UserAPI
  mount FilesMockServer::UserCipherUseAPI
  mount FilesMockServer::UserRequestAPI
end
