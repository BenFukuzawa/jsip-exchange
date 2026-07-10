(** Central event-routing component for the gateway.

    Owns subscription registries:

    - **Market-data subscribers**, keyed by [Symbol.t]. Each subscriber gets
      a pipe of [Best_bid_offer_update] and [Trade_report] events for the
      symbol they asked about. This is the public market-data feed.

    - **Audit subscribers**, an unfiltered firehose of every event the
      matching engine produces. Intended for the exchange operator's monitor;
      not appropriate to expose to ordinary clients.

    [dispatch] is the single place that decides "for each event, who gets
    it". *)

open! Core
open! Async
open Jsip_types
open Jsip_exchange_stats

type t =
  { market_data_subscribers_by_symbol :
      Exchange_event.t Pipe.Writer.t Bag.t Symbol.Table.t
  ; audit_subscribers : Exchange_event.t Pipe.Writer.t Bag.t
  ; active_sessions : Session.t Participant_id.Table.t
  ; registry : Participant_registry.t
  }

(** Create a dispatcher.

    Events whose audience is a single participant (order-lifecycle responses
    and [Fill] events) are currently handed to a stub [push_to_session] that
    prints them on stdout, prefixed with the target participant. Wiring this
    up to real [Session] outbound pipes is a week-2 exercise. *)
val create : Participant_registry.t -> t

(** Subscribe to public market data for one or more [symbols]. The same pipe
    receives events for every requested symbol; the dispatcher avoids
    duplicates so a subscriber listed against multiple symbols only sees each
    event once. The pipe is removed from the dispatcher when its reader is
    closed. *)
val subscribe_market_data
  :  t
  -> Symbol.t list
  -> Exchange_event.t Pipe.Reader.t

(** Subscribe to the full unfiltered event firehose. Intended for the monitor
    / admin tools. *)
val subscribe_audit : t -> Exchange_event.t Pipe.Reader.t

(** Route each event to every interested subscriber:

    - Every event is pushed to every audit subscriber.
    - [Best_bid_offer_update] and [Trade_report] are pushed to the
      market-data subscribers that asked for the event's symbol.
    - [Order_accept], [Order_cancel], and [Order_reject] are pushed to the
      session of the order's owning participant (if logged in).
    - [Fill] is pushed to both the aggressor's and the resting party's
      session (if either is logged in).

    Each session lookup is O(1) and independent of subscriber count. *)
val dispatch : t -> Exchange_event.t list -> unit

(** Queue length of every subscriber pipe this dispatcher writes to, grouped
    by feed family. Sampled once per second by the exchange-stats loop in
    {!Exchange_server}; costs O(subscribers), not O(queued events). None of
    these pipes is bounded yet (they are written with
    [Pipe.write_without_pushback_if_open]), so a slow consumer shows up here
    as a queue that grows without limit. *)
val pipe_occupancy : t -> Exchange_stats.Pipe_occupancy.t

module For_testing : sig
  val audit_subscriber_count : t -> int
end

val clean_up_session : t -> Session.t -> unit Deferred.t
val set_up_session : t -> Participant.t -> unit Deferred.t
