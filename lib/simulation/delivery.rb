module FilesMockServer
  module Simulation
    # Responses a fault rule makes instead of, or out of, the simulator's own (FaultRules::KINDS):
    # bodies a web tier or storage provider sends, and responses held back, dropped, cut short, padded
    # or paused on the connection. Connection faults write the response themselves through Rack's
    # full hijack. Delivery runs outside the App's lock.
    module Delivery
      # What an expired presigned storage URL answers, as Amazon S3 does.
      EXPIRED_URL = %(<?xml version="1.0" encoding="UTF-8"?>\n<Error><Code>AccessDenied</Code><Message>Request has expired</Message></Error>\n).freeze
      # A web page where file bytes were expected, as the Files.com web front end answers, marked with
      # its X-Files-Frontend-App header.
      HTML_PAGE = %(<!DOCTYPE html>\n<html><head><title>Files.com</title></head><body><p>Sign in to continue.</p></body></html>\n).freeze
      # The bytes excess_body sends after the body.
      FILLER = "X".freeze

      # The response a rule sends instead of applying the request, or nil when its kind sends none.
      # A redirect's Location is the rule's origin followed by the request's path and query.
      def self.answer(rule, request)
        headers = { "x-files-mock-fault" => rule.id.to_s }
        case rule.kind
        when "redirect" then [ rule.status, headers.merge("location" => rule.location.delete_suffix("/") + request.fullpath), [] ]
        when "unstructured"
          headers["retry-after"] = rule.retry_after.to_s if rule.retry_after
          heading = "#{rule.status} #{Rack::Utils::HTTP_STATUS_CODES.fetch(rule.status)}"
          [ rule.status, headers.merge("content-type" => "text/html"), [ "<html><head><title>#{heading}</title></head><body><h1>#{heading}</h1></body></html>\n" ] ]
        when "expired_url" then [ 403, headers.merge("content-type" => "application/xml"), [ EXPIRED_URL ] ]
        when "html_page" then [ 200, headers.merge("content-type" => "text/html; charset=utf-8", "x-files-frontend-app" => "true"), [ HTML_PAGE ] ]
        end
      end

      # The journal's record of how a rule applied after the request delivers its response: the
      # body's size and how many bytes are sent (and, for a stall, where it pauses).
      def self.plan(rule, response)
        return { "delay_ms" => rule.delay_ms } if rule.kind == "delay"
        return { "sent_bytes" => 0 } if rule.kind == "drop_after"
        return {} unless FaultRules::BODY_KINDS.include?(rule.kind)

        size = body_size(response.last)
        cut = [ rule.bytes, size ].min
        sent = { "truncate" => cut, "short_body" => size - cut, "excess_body" => size + rule.bytes, "stall" => size }.fetch(rule.kind)
        { "body_bytes" => size, "sent_bytes" => sent, "paused_at" => (cut if rule.kind == "stall") }.compact
      end

      # Delivers the response to a request a rule applied after, or drops the connection of one it
      # was not applied for (drop_before, with no response).
      def self.deliver(env, rule, response)
        if rule.kind == "delay"
          sleep(rule.delay_ms / 1000.0)
          return response
        end

        io = env.fetch("rack.hijack").call
        begin
          write(io, rule, response) if response && rule.kind != "drop_after"
        rescue IOError, SystemCallError
          # The client closed the connection first.
        ensure
          response.last.close if response&.last.respond_to?(:close)
          begin
            io.close
          rescue IOError, SystemCallError
            nil
          end
        end
        # The server ignores the response of a hijacked request.
        [ 200, {}, [] ]
      end

      def self.write(io, rule, response)
        status, headers, body = response
        bytes = +"".b
        body.each { |chunk| bytes << chunk.b }
        cut = [ rule.bytes, bytes.bytesize ].min
        omit = %w[connection transfer-encoding]
        omit << "content-length" if %w[short_body excess_body].include?(rule.kind)
        head = "HTTP/1.1 #{status} #{Rack::Utils::HTTP_STATUS_CODES.fetch(status)}\r\n"
        headers.each { |name, value| head << "#{name}: #{value}\r\n" unless omit.include?(name.downcase) }
        head << "connection: close\r\n\r\n"
        # One string per write: a TLS connection's socket takes a single argument.
        case rule.kind
        when "truncate" then io.write(head.b + bytes.byteslice(0, cut))
        when "short_body" then io.write(head.b + bytes.byteslice(0, bytes.bytesize - cut))
        when "excess_body" then io.write(head.b + bytes + (FILLER * rule.bytes))
        when "stall"
          io.write(head.b + bytes.byteslice(0, cut))
          io.flush
          sleep(rule.delay_ms / 1000.0)
          io.write(bytes.byteslice(cut..))
        end
      end

      def self.body_size(body)
        body.respond_to?(:bytesize) ? body.bytesize : body.sum(&:bytesize)
      end
      private_class_method :write, :body_size
    end
  end
end
